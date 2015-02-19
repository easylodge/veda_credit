class VedaCredit::ConsumerResponse < ActiveRecord::Base
  self.table_name = "veda_credit_consumer_responses"
  
  belongs_to :consumer_request, dependent: :destroy

  serialize :headers
  serialize :as_hash
  
  validates :consumer_request_id, presence: true
  validates :xml, presence: true

  before_save :to_hash
  
  def self.nested_hash_value(obj,key)
    if obj.respond_to?(:key?) && obj.key?(key)
      obj[key]
    elsif obj.respond_to?(:each)
      r = nil
      obj.find{ |*a| r=nested_hash_value(a.last,key) }
      r
    end
  end

  def error
    bca_error = VedaCredit::ConsumerResponse.nested_hash_value(self.as_hash, "BCAerror")
    product_error = VedaCredit::ConsumerResponse.nested_hash_value(self.as_hash, "error")
    if bca_error
      self.as_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["BCAerror"]["BCAerror_description"]
    elsif product_error
      ("#{product_error["error_type"].humanize} error: #{product_error["input_container"]}, #{product_error["error_description"]}" rescue "There was an Veda product error")
    else        
      nil
    end
  end

  def validate_xml
    xsd = Nokogiri::XML::Schema(self.schema)
    doc = Nokogiri::XML(self.xml)
    xsd.validate(doc).each do |error|
      error.message
    end     
  end

  def schema
    fname = File.expand_path('../../lib/assets/Vedascore-individual-enquiries-response-version-1.1.xsd', File.dirname(__FILE__) )
    File.read(fname)
  end

  def to_s
    "Veda Credit Consumer Response"
  end

  def enquiry_report
    to_hash unless as_hash
    as_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"] rescue {}
  end

  def primary_match
    enquiry_report["primary_match"]
  end

  def score_data
    enquiry_report["score_data"]
  end

  def summary_data
    doc = Nokogiri::XML(self.xml)
    hsh = {}
    doc.xpath("//summary").each do |el|
      if el.text.present? && (el.text =~ /^\d+$/)
        hsh[el.xpath("@name").text.underscore] = el.text.to_i
      elsif el.text.present?
        hsh[el.xpath("@name").text.underscore] = el.text
      else
        "nil"
      end
    end
    hsh
  end

  def number_of_cross_references
    primary_match["individual_consumer_credit_file"]["individual_cross_reference"].count rescue 0
  end

  def number_of_bankruptcies
    primary_match["individual_public_data_file"]["bankruptcy"].select{|x| x["discharged_status"].blank? }.count rescue 0
  end

  def number_of_discharged_bankruptcies
    primary_match["individual_public_data_file"]["bankruptcy"].select{|x| !x["discharged_status"].blank? }.count rescue 0
  end

  def number_of_discharged_bankruptcies_last_12_months
    return 0 unless primary_match["individual_public_data_file"]["bankruptcy"].select{|x| !x["discharged_status"].blank? }.count > 0 rescue false
    total =  primary_match["individual_public_data_file"]["bankruptcy"].select{|x| !x["discharged_status"].blank? } rescue {}
    total = total.select{|x| (x["discharged_status"]["date"].to_date >= 12.months.ago rescue false) }.count rescue 0
  end

  def number_of_part_x_bankruptcies
    primary_match["individual_public_data_file"]["bankruptcy"].select{|x| x["bankruptcy_type"] == "Personal Insolvency Agreement (Part 10 Deed)" }.count rescue 0
  end

  def number_of_part_ix_bankruptcies
    primary_match["individual_public_data_file"]["bankruptcy"].select{|x| x["bankruptcy_type"] == "Debt Agreement (Part 9)" }.count rescue 0
  end


  def number_of_clearout
    return 0 unless primary_match["individual_consumer_credit_file"]["default"].count > 0 rescue false
    primary_match["individual_consumer_credit_file"]["default"].select{ |key,val| key != "account_details" && val["reason_to_report"] == "Clearout" }.count rescue 0
  end

  def last_36_months_paid_defaults_amount
    return 0 unless primary_match["individual_consumer_credit_file"]["default"].count > 0 rescue false
    paid_defaults = primary_match["individual_consumer_credit_file"]["default"].select{ |key,val| key != "account_details" && (val["date_recorded"].to_date >= 36.months.ago rescue false ) && val["reason_to_report"] == "Payment Default" }
    paid_defaults = paid_defaults.collect{|key, val| val["default_amount"]}
    paid_defaults.sum
  end

  def last_36_months_unpaid_defaults_amount
    return 0 unless primary_match["individual_consumer_credit_file"]["default"].count > 0 rescue false
    unpaid_defaults = primary_match["individual_consumer_credit_file"]["default"].select{ |key,val| key != "account_details" && (val["date_recorded"].to_date >= 36.months.ago rescue false ) && val["reason_to_report"] != "Payment Default" }
    unpaid_defaults = unpaid_defaults.collect{|key, val| val["default_amount"]}
    unpaid_defaults.sum
  end

  def file_message
    primary_match["individual_consumer_credit_file"]["file_message"] rescue nil
  end

  def bureau_reference
    primary_match["bureau_reference"] rescue nil
  end

  def individual
    return {} unless (primary_match["individual"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual"]))
    hsh["first_name"] = hsh["individual_name"]["first_given_name"] rescue nil
    hsh["surname"] = hsh["individual_name"]["family_name"] rescue nil
    hsh["gender"] = hsh["gender"]["code"] rescue nil
    if hsh["address"] && hsh["address"].is_a?(Array) && hsh["address"].present?
      hsh["address"].each do |addr|
        addr["street_type"] = addr["street_type"]["code"] rescue nil
        addr["country"] = addr["country"]["country_code"] rescue nil
      end
    else
      hsh["address"]["street_type"] = hsh["address"]["street_type"]["code"] rescue nil
      hsh["address"]["country"] = hsh["address"]["country"]["country_code"] rescue nil
    end
    hsh.delete("individual_name")
    hsh["address"].delete("create_date")
    hsh
  end  

  def defaults
    return {} unless (primary_match["individual_consumer_credit_file"]["default"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["default"]))
    hsh["account_details"]["role"] = hsh["account_details"]["role"]["code"] rescue nil
    hsh
  end

  def credit_enquiries
    return {} unless (primary_match["individual_consumer_credit_file"]["credit_enquiry"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["credit_enquiry"]))
    if hsh.is_a?(Array) && hsh.present?
      hsh.each do |cred|
        cred["role"] = cred["role"]["code"] rescue nil
      end
    else
      hsh["role"] = hsh["role"]["code"] rescue nil
    end
    hsh
  end

  def court_actions
    return {} unless (primary_match["individual_public_data_file"]["court_action"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["court_action"]))
    if hsh.is_a?(Array) && hsh.present?
      hsh.each do |el|
        el["role"] = el["role"]["code"] rescue nil
      end
    else
      hsh["role"] = hsh["role"]["code"] rescue nil
    end
    hsh 
  end

  def directorship
    return {} unless (primary_match["individual_public_data_file"]["directorship"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["directorship"]))
    hsh["organisation"]["organisation_type"] = hsh["organisation"]["organisation_type"]["code"]
    hsh
  end

  def bankruptcy
    return {} unless (primary_match["individual_public_data_file"]["directorship"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["bankruptcy"]))
    hsh["role"] = hsh["role"]["code"] rescue nil
    hsh
  end

  private  
  def to_hash
    return nil unless self.xml.present?
    new_xml = self.xml.gsub('gender type','gender code').gsub('role type','role code')
    self.as_hash = Hash.from_xml(new_xml)
  end

end