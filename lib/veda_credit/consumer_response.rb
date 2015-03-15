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

  def service_request_id
    as_hash["BCAmessage"]["service_request_id"] rescue ""
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
        val = (el.xpath("@type").text =~ /amount/) ? el.text.to_i : "#{el.text.to_i} #{el.xpath("@type").text}"
        val = el.text if (el.xpath("@type").text =~ /count/)
        hsh[el.xpath("@name").text.underscore] = val
      elsif el.text.present?
        val = (el.xpath("@type").text =~ /amount/) ? el.text : "#{el.text} #{el.xpath("@type").text}"
        val = el.text if (el.xpath("@type").text =~ /count/)
        hsh[el.xpath("@name").text.underscore] = val
      else
        "nil"
      end
    end
    hsh
  end

  def number_of_cross_references
    [primary_match["individual_consumer_credit_file"]["individual_cross_reference"]].flatten.count rescue 0
  end

  #Discharged status: 'not-discharged-not-completed', 'completed', 'discharged'
  def number_of_bankruptcies
    [primary_match["individual_public_data_file"]["bankruptcy"].select{|x| x["discharge_status"]["code"] == "not-discharged-not-completed" }].flatten.count rescue 0
  end

  def discharged_bankruptcies
    [primary_match["individual_public_data_file"]["bankruptcy"].select{|x| !x["discharge_status"]["code"] == "discharged" }].flatten rescue []
  end

  def number_of_discharged_bankruptcies
    self.discharged_bankruptcies.count rescue 0
  end

  def number_of_discharged_bankruptcies_last_12_months
    return 0 unless self.discharged_bankruptcies.count > 0 rescue false
    discharged_bankruptcies.select{|x| (x["discharge_status"]["date"].to_date >= 12.months.ago rescue false) }.count rescue 0
  end

  def number_of_part_x_bankruptcies
    return 0 unless self.bankruptcies.count > 0
    self.bankruptcies.select{|x| x["type"] == "Personal Insolvency Agreement (Part 10 Deed)" }.count rescue 0
  end

  def number_of_part_ix_bankruptcies
    return 0 unless self.bankruptcies.count > 0
    self.bankruptcies.select{|x| x["type"] == "Debt Agreement (Part 9)" }.count rescue 0
  end

  def number_of_clearout
    return 0 unless self.defaults.count > 0
    defaults.select{ |key,val| key != "account_details" && val["reason_to_report"] == "Clearout" }.count rescue 0
  end

  def last_36_months_paid_defaults_amount
    return 0 unless self.defaults.count > 0
    paid_defaults = defaults.select{ |key,val| key != "account_details" && (val["date_recorded"].to_date >= 36.months.ago rescue false ) && val["reason_to_report"] == "Payment Default" }
    paid_defaults = paid_defaults.collect{|key, val| val["default_amount"]}
    paid_defaults.sum
  end

  def last_36_months_unpaid_defaults_amount
    return 0 unless self.defaults.count > 0
    unpaid_defaults = defaults.select{ |key,val| key != "account_details" && (val["date_recorded"].to_date >= 36.months.ago rescue false ) && val["reason_to_report"] != "Payment Default" }
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
    return [] unless (primary_match["individual"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual"]))
    hsh["full_name"] = [(hsh["individual_name"]["first_given_name"] rescue nil), (hsh["individual_name"]["other_given_name"] rescue nil), (hsh["individual_name"]["family_name"] rescue nil)].join(' ')
    hsh["gender"] = hsh["gender"]["code"] rescue nil

    if hsh["address"] && hsh["address"].present?
      addr_hash = []
      [hsh["address"]].flatten.each do |addr|
        address_type = addr["type"].gsub('-', ' ').humanize rescue nil
        address_line_1 = [(addr["street_number"] rescue nil), (addr["street_name"] rescue nil), (addr["street_type"]["code"] rescue nil)].join(' ')
        address_line_2 = [(addr["suburb"] rescue nil), (addr["state"] rescue nil), (addr["postcode"] rescue nil)].join(' ')
        complete_address = [address_line_1, address_line_2, (addr["country"]["country_code"] rescue nil)].join(', ')
        addr_hash << {"address_type" => address_type, "address" => complete_address, "create_date" => (addr["create_date"] rescue nil)}
      end
      hsh["address"] = addr_hash
    end
    hsh["file_create_date"] = hsh["individual_name"]["create_date"]
    hsh.delete("employment")
    hsh.delete("individual_name")
    hsh
  end

  def defaults
    return [] unless (primary_match["individual_consumer_credit_file"]["default"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["default"]))
    defaults_hash = []
    [hsh].flatten.each do |default|
      tmp_hash = {"section" => "Default",
<<<<<<< HEAD
                  "type" => [(default["account_details"]["account_type"] rescue nil),
=======
                  "type" => [(default["account_details"]["account_type"] rescue nil),
>>>>>>> 4b498e177f4926dcfe498d0230216d81cba14eaf
                             (default["account_details"]["default_status"] rescue nil),
                             (default["original_default"]["reason_to_report"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (default["original_default"]["date_recorded"] rescue nil),
                  "creditor" => (default["original_default"]["credit_provider"] rescue nil),
                  "current_amount" => (default["current_default"]["default_amount"] rescue nil),
                  "original_amount" => (default["original_default"]["default_amount"] rescue nil),
<<<<<<< HEAD
                  "role" => (default["account_details"]["role"]["code"] rescue nil),
=======
                  "role" => (default["account_details"]["role"]["code"] rescue nil),
>>>>>>> 4b498e177f4926dcfe498d0230216d81cba14eaf
                  "reference" => (default["account_details"]["client_reference"] rescue nil)}
      defaults_hash << tmp_hash
    end
    defaults_hash
  end

  def credit_enquiries
    return [] unless (primary_match["individual_consumer_credit_file"]["credit_enquiry"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["credit_enquiry"]))
    [hsh].flatten.each do |cred|
      cred["role"] = cred["role"]["code"] rescue nil
    end
    [hsh].flatten
  end

  def court_actions
    return [] unless (primary_match["individual_public_data_file"]["court_action"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["court_action"]))
    court_action_hash = []
    [hsh].flatten.each do |ca|
      tmp_hash = {"section" => "Court Action",
                  "type" => [(ca["type"].gsub('-', ' ').humanize rescue nil),
                             (ca["court_type"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (ca["action_date"] rescue nil),
                  "creditor" => (ca["creditor"] rescue nil),
                  "court_action_amount" => (ca["court_action_amount"].to_i rescue nil),
                  "role" => (ca["role"]["code"] rescue nil),
                  "reference" => (ca["plaint_number"] rescue nil)}
      court_action_hash << tmp_hash
    end
    court_action_hash
  end

  def directorships
    return [] unless (primary_match["individual_public_data_file"]["directorship"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["directorship"]))
    [hsh].flatten.each do |el|
      el["organisation_bureau_reference"] = el["organisation"]["bureau_reference"] rescue nil
      el["organisation_name"] = "#{el["organisation"]["organisation_name"]} #{el["organisation"]["organisation_type"]["code"]}" rescue nil
      el.delete("organisation")
    end
    [hsh].flatten
  end

  def bankruptcies
    return [] unless (primary_match["individual_public_data_file"]["bankruptcy"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["bankruptcy"]))
    bankrupt_hash = []
    [hsh].flatten.each do |bnkr|
      tmp_hash = {"section" => "Bankruptcy",
                  "type" => [(bnkr["bankruptcy_type"] rescue nil),
                             (bnkr["proceedings"]["proceedings_status"]["code"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (bnkr["date_declared"] rescue nil),
                  "role" => (bnkr["role"]["code"] rescue nil),
                  "discharge_status" => (bnkr["discharge_status"]["code"] rescue nil)}
      bankrupt_hash << tmp_hash
    end
    bankrupt_hash
  end

  def cross_references
    return [] unless (primary_match["individual_consumer_credit_file"]["individual_cross_reference"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["individual_cross_reference"]))
    [hsh].flatten.each do |el|
      el["individual"] = [(el["individual_name"]["first_given_name"] rescue nil), (el["individual_name"]["other_given_name"] rescue nil), (el["individual_name"]["family_name"] rescue nil)].join(' ')
      el.delete("individual_name")
    end
    [hsh].flatten
  end

  def employment_histories
    return [] unless (primary_match["individual"]["employment"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual"]["employment"]))
    [hsh].flatten
  end

  private
  def to_hash
    return nil unless self.xml.present?
    new_xml = self.xml.gsub('gender type','gender code')\
                      .gsub('role type','role code')\
                      .gsub('proceedings-status type','proceedings-status code')\
                      .gsub('discharge-status type','discharge-status code')
    self.as_hash = Hash.from_xml(new_xml)
  end

end
