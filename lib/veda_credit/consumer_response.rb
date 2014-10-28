class VedaCredit::ConsumerResponse < ActiveRecord::Base
  self.table_name = "veda_credit_consumer_responses"
  
  belongs_to :consumer_request, dependent: :destroy

  # serialize :headers
  serialize :as_hash
  
  validates :consumer_request_id, presence: true
  validates :xml, presence: true
  # validates :headers, presence: true
  # validates :code, presence: true
  # validates :success, presence: true

  after_initialize :to_hash
  
  def to_hash
    hash = Hash.from_xml(self.xml)
    self.as_hash = hash
  end

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
    bca_error = VedaCredit::ConsumerResponse.nested_hash_value(self.to_hash, "BCAerror")
    product_error = VedaCredit::ConsumerResponse.nested_hash_value(self.to_hash, "error")
    if bca_error
      self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["BCAerror"]["BCAerror_description"]
    elsif product_error
      ("#{product_error["error_type"].humanize} error: #{product_error["input_container"]}, #{product_error["error_description"]}" rescue "There was an Veda product error")
    else        
      "No Error"
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

  # def primary_match
  #   self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"] rescue {}
  # end

  # def score_data
  #   self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["score_data"] rescue {}
  # end

  # def summary_data
  #   doc = Nokogiri::XML(self.xml)
  #   hash = {}
  #   doc.xpath("//summary").each do |el|
  #     if el.text.present? && (el.text =~ /^\d+$/)
  #       hash[el.xpath("@name").text.underscore] = el.text.to_i
  #     elsif el.text.present?
  #       hash[el.xpath("@name").text.underscore] = el.text
  #     else
  #       "nil"
  #     end
  #   end
  #   hash
  # end

  def to_s
    "Veda Credit Consumer Response"
  end

  def enquiry_report
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