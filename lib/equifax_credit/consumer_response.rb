class EquifaxCredit::ConsumerResponse < ActiveRecord::Base
  self.table_name = "equifax_credit_consumer_responses"

  belongs_to :consumer_request, dependent: :destroy

  serialize :headers
  serialize :as_hash

  validates :consumer_request_id, presence: true
  validates :xml, presence: true

  before_save :to_hash

  # NOTE:
  # The current free-for-all naming convention used in this file leaves much to be desired.
  # When adding a new method, try to name it like this:
  # thing_term_amount, thing_total_amount, thing_term_count, thing_total_count
  # where "thing" is something like credit_clearouts or unpaid defaults
  # and where "term" is typically 12, 36 etc months. Feel free to use some meta code to organise all the terms together.


  # [:total, :count, 3, 6, 9, 12, 24, 36, 48, 60, 72].each do |term|
  #   case term
  #   when :total
  #     define_method("example_#{term}".to_sym) do
  #       # total regardless of term range
  #     end
  #   when :count
  #   else
  #     define_method("example_#{term}".to_sym) do
  #       # return only entries for the term range
  #     end
  #     define_method("example_#{term}_amount".to_sym) do
  #       # sum only relevant entries
  #       # self.send("example_#{term}".to_sym).sum(:something)
  #     end
  #     define_method("example_#{term}_count".to_sym) do
  #       # count only relevant entries
  #       # self.send("example_#{term}".to_sym).count
  #     end
  #   end
  # end

  def self.nested_hash_value(obj,key)
    if obj.respond_to?(:key?) && obj.key?(key)
      obj[key]
    elsif obj.respond_to?(:each)
      r = nil
      obj.find{ |*a| r=nested_hash_value(a.last,key) }
      r
    end
  end

  def consumer_plus_commercial?
    self.consumer_request.enquiry[:product_name] == "vedascore-financial-consumer-plus-commercial-1.1" rescue false
  end

  def commercial_plus_consumer?
    #added commercial to give backward compatibility for reports
    (["vedascore-financial-commercial-1.1", "vedascore-financial-commercial-plus-consumer-1.1"].include? self.consumer_request.enquiry[:product_name]) rescue false
  end

  def commercial_service_version
    if ["vedascore-financial-commercial-1.1", "company-business-enquiry", "company-business-broker-dealer-enquiry", "vedascore-financial-commercial-plus-consumer-1.1"].include? self.consumer_request.enquiry[:product_name]
      "Old"
    else
      "Consumer"
    end
  end

  def age_of_file
    return nil unless primary_match.present?
    create_date = primary_match["individual"]["individual_name"]["create_date"]
    return nil unless create_date.present?
    now = DateTime.now
    create_date = create_date.to_date
    (now.year * 12 + now.month) - (create_date.year * 12 + create_date.month)
  end

  def service_version
    self.consumer_request.enquiry[:product_name] rescue nil
  end

  def error
    bca_error = EquifaxCredit::ConsumerResponse.nested_hash_value(self.as_hash, "BCAerror")
    product_error = EquifaxCredit::ConsumerResponse.nested_hash_value(self.as_hash, "error")
    if bca_error
      service_request = self.as_hash["BCAmessage"]["service_request_id"]
      error = self.as_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["BCAerror"]["BCAerror_description"]
      "Service Request: #{service_request} - #{error}"
    elsif product_error
      ("#{product_error["error_type"].humanize} error: #{product_error["input_container"]}, #{product_error["error_description"]}" rescue "There was an Veda product error")
    else
      nil
    end
  end

  def success?
    error.nil? ? true : false
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
    "Equifax Credit Consumer Response"
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

  def possible_matches
    return [] unless (enquiry_report["possible_match"] rescue false)
    hsh = Marshal.load(Marshal.dump(enquiry_report["possible_match"]))
    possible_matches_array = []
    [hsh].flatten.each do |match|
      type = (match["individual"].present? && "individual") || (match["organisation"].present? && "organisation") || (match["business"].present? && "business")
      if (match[type]["address"] rescue nil) && (match[type]["address"].present? rescue nil)
        addr_hash = []
        [match[type]["address"]].flatten.each do |addr|
          address_type = addr["type"].gsub('-', ' ').humanize rescue nil
          address_line_1 = [(addr["street_number"] rescue nil), (addr["street_name"] rescue nil), (addr["street_type"]["code"] rescue nil)].join(' ')
          address_line_2 = [(addr["suburb"] rescue nil), (addr["state"] rescue nil), (addr["postcode"] rescue nil)].join(' ')
          complete_address = [address_line_1, address_line_2, (addr["country"]["country_code"] rescue nil)].join(', ')
          addr_hash << {"address_type" => address_type, "address" => complete_address, "create_date" => (addr["create_date"] rescue nil)}
        end
        match[type]["address"] = addr_hash
      end
      name = ( [(match["individual"]["individual_name"]["first_given_name"] rescue nil), (match["individual"]["individual_name"]["other_given_name"] rescue nil), (match["individual"]["individual_name"]["family_name"] rescue nil)].compact.join(' ') rescue nil )
      name = name.present? ? name : ( [(match["organisation"]["organisation_name"] rescue nil ), (match["organisation"]["organisation_type"]["code"] rescue nil )].compact.join(' ') rescue nil )
      name = name.present? ? name : (match["business"]["business_name"] rescue nil )
      tmp_hash = {
        "type" => type,
        "bureau_reference" => (match["bureau_reference"] rescue nil),
        "name" => name,
        "organisation_number" => (match["organisation"]["organisation_number"] rescue nil ),
        "abn_number" => (match["organisation"]["australian_business_number"] rescue nil) || (match["business"]["australian_business_number"] rescue nil),
        "gender" => (match["individual"]["gender"]["code"] rescue nil),
        "date_of_birth" => (match["individual"]["date_of_birth"] rescue nil),
        "drivers_licence_number" => (match["individual"]["drivers_licence_number"] rescue nil),
        "file_create_date" => (match["individual"]["individual_name"]["create_date"] rescue nil) || (match["organisation"]["file_create_date"] rescue nil) || (match["business"]["file_create_date"] rescue nil),
        "employment" => (match["individual"]["employment"] rescue nil),
        "addresses" => ((match["individual"]["address"] rescue nil) || (match["organisation"]["address"] rescue nil) || (match["business"]["address"] rescue nil))
      }
      possible_matches_array << tmp_hash.with_indifferent_access
    end
    possible_matches_array
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
        val = (el.xpath("@type").text =~ /amount/) ? el.text : "#{el.text + (el.xpath("@type").text.blank? ? "" : el.xpath("@type").text )}"
        val = el.text if (el.xpath("@type").text =~ /count/)
        hsh[el.xpath("@name").text.underscore] = val
      else
        "nil"
      end
    end
    hsh
  end

  def number_of_cross_references
    self.cross_references.count
  end

  #Discharged status: 'not-discharged-not-completed', 'completed', 'discharged'
  def number_of_bankruptcies
    self.bankruptcies.select{|x| "not-discharged-not-completed" == x["discharge_status"] }.count
  end

  def discharged_bankruptcies
    self.bankruptcies.select{|x| "discharged" == x["discharge_status"] } rescue []
  end

  def number_of_discharged_bankruptcies
    self.discharged_bankruptcies.count
  end

  [12, 24, 36, 48, 60, 72].each do |term|
    define_method("number_of_discharged_bankruptcies_last_#{term}_months".to_sym) do
      discharged_bankruptcies.select{|x| (x["discharge_date"].to_date >= term.months.ago rescue false) }.count
    end
  end

  def number_of_part_x_bankruptcies
    self.bankruptcies.select{|x| x["type"] =~ /Personal Insolvency Agreement (Part 10 Deed)/ || x["type"] =~ /Part 10/ || x["type"] =~ /part 10/ }.count
  end

  def number_of_part_ix_bankruptcies
    self.bankruptcies.select{|x| x["type"] =~ /Debt Agreement (Part 9)/ || x["type"] =~ /Part 9/ || x["type"] =~ /part 9/ }.count
  end

  def number_of_clearouts
    defaults.select{|d| d[:reason_to_report] == "Clearout"}.count
  end
  alias_method :number_of_clearout, :number_of_clearouts

  def paid_defaults
    # defaults.select{|key,val| key != "account_details" && val["reason_to_report"] == "Payment Default" }
    # defaults.select{|d| d[:reason_to_report] == "Payment Default" }
    defaults.select {|d| (d["type"].split(",")[1] == "Paid") rescue nil }
  end

  def unpaid_defaults
    # defaults.select{ |key,val| key != "account_details" && val["reason_to_report"] != "Payment Default" }
    # defaults.select{|d| d[:reason_to_report] != "Payment Default" }
    defaults.select {|d| (d["type"].split(",")[1] == "Outstanding") rescue nil }
  end

  def credit_defaults
    defaults.select {|d| ["Telecommunication Service", "Utilities"].exclude?(d["type"].split(",").first) rescue nil }
  end

  def non_credit_defaults
    defaults.select {|d| ["Telecommunication Service", "Utilities"].include?(d["type"].split(",").first) rescue nil }
  end

  def current_credit_defaults
    credit_defaults.select {|d| "C" == d["status_code"] rescue nil }
  end

  def current_non_credit_defaults
    non_credit_defaults.select {|d| "C" == d["status_code"] rescue nil }
  end

  def credit_clearouts
    defaults.select{|d| d[:current_reason_to_report_code] == "C"}
  end

  [11, 12, 18, 24, 35, 36, 48, 60, 72].each do |term|
    define_method("paid_defaults_#{term}".to_sym) do
      paid_defaults.select{|d| d[:date_recorded].to_date >= term.months.ago}
    end

    define_method("paid_defaults_#{term}_amount".to_sym) do
      self.send("paid_defaults_#{term}".to_sym).collect{|d| d[:default_amount].to_f}.sum
    end

    define_method("paid_defaults_#{term}_count".to_sym) do
      self.send("paid_defaults_#{term}".to_sym).count
    end

    define_method("unpaid_defaults_#{term}".to_sym) do
      unpaid_defaults.select{|d| d[:date].to_date >= term.months.ago}
    end

    define_method("unpaid_defaults_#{term}_amount".to_sym) do
      self.send("unpaid_defaults_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("unpaid_defaults_#{term}_count".to_sym) do
      self.send("unpaid_defaults_#{term}".to_sym).count
    end

    #support the old names for backwards compatibility
    alias_method "last_#{term}_months_paid_defaults_amount".to_sym, "paid_defaults_#{term}_amount".to_sym
    alias_method "last_#{term}_months_unpaid_defaults_amount".to_sym, "unpaid_defaults_#{term}_amount".to_sym

    define_method("non_credit_clearouts_#{term}".to_sym) do
      non_credit_defaults.select{|d| d[:current_reason_to_report_code] == "C" && d[:date].to_date >= term.months.ago}
    end

    define_method("non_credit_clearouts_#{term}_amount".to_sym) do
      self.send("non_credit_clearouts_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("non_credit_clearouts_#{term}_count".to_sym) do
      self.send("non_credit_clearouts_#{term}".to_sym).count
    end

    define_method("credit_clearouts_#{term}".to_sym) do
      credit_clearouts.select{|d| d[:date].to_date >= term.months.ago.to_date}
    end

    define_method("credit_clearouts_#{term}_amount".to_sym) do
      self.send("credit_clearouts_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("credit_clearouts_#{term}_count".to_sym) do
      self.send("credit_clearouts_#{term}".to_sym).count
    end

    define_method("paid_non_credit_defaults_#{term}".to_sym) do
      paid_non_credit_defaults.select{|d| d[:date].to_date >= term.months.ago}
    end

    define_method("paid_non_credit_defaults_#{term}_amount".to_sym) do
      self.send("paid_non_credit_defaults_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("paid_credit_defaults_#{term}".to_sym) do
      paid_credit_defaults.select{|d| d[:date].to_date >= term.months.ago}
    end

    define_method("paid_credit_defaults_#{term}_amount".to_sym) do
      self.send("paid_credit_defaults_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("unpaid_non_credit_defaults_#{term}".to_sym) do
      unpaid_non_credit_defaults.select{|d| d[:date].to_date >= term.months.ago}
    end

    define_method("unpaid_non_credit_defaults_#{term}_amount".to_sym) do
      self.send("unpaid_non_credit_defaults_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end

    define_method("unpaid_credit_defaults_#{term}".to_sym) do
      unpaid_credit_defaults.select{|d| d[:date].to_date >= term.months.ago}
    end

    define_method("unpaid_credit_defaults_#{term}_amount".to_sym) do
      self.send("unpaid_credit_defaults_#{term}".to_sym).collect{|d| d[:current_amount].to_f}.sum
    end
  end

  def defaults_total
    defaults.collect{|default| default[:current_amount].to_f}.sum
  end

  def paid_defaults_total
    paid_defaults.collect{|default| default[:original_amount].to_f}.sum
  end
  alias_method :paid_defaults_total_amount, :paid_defaults_total

  def unpaid_defaults_total
    unpaid_defaults.collect{|d| d[:current_amount].to_f}.sum
  end
  alias_method :unpaid_defaults_total_amount, :unpaid_defaults_total

  def credit_defaults_total
    credit_defaults.collect{|d| d[:current_amount].to_f}.sum
  end

  def non_credit_defaults_total
    non_credit_defaults.collect{|d| d[:current_amount].to_f}.sum
  end

  def current_credit_defaults_total
    current_credit_defaults.collect{|d| d[:current_amount].to_f}.sum
  end

  def current_non_credit_defaults_total
    current_non_credit_defaults.collect{|d| d[:current_amount].to_f}.sum
  end

  def paid_non_credit_defaults
    paid_defaults.select{|d| ["Telecommunication Service", "Utilities"].include?(d["type"].split(",").first) rescue nil }
  end

  def paid_credit_defaults
    paid_defaults.select{|d| ["Telecommunication Service", "Utilities"].exclude?(d["type"].split(",").first) rescue nil }
  end

  def paid_non_credit_defaults_total
    paid_defaults.select{|d| ["Telecommunication Service", "Utilities"].include?(d["type"].split(",").first) rescue nil }.collect{|d| d[:current_amount].to_f}.sum
  end

  def paid_credit_defaults_total
    paid_defaults.select{|d| ["Telecommunication Service", "Utilities"].exclude?(d["type"].split(",").first) rescue nil }.collect{|d| d[:current_amount].to_f}.sum
  end

  def unpaid_non_credit_defaults
    unpaid_defaults.select{|d| ["Telecommunication Service", "Utilities"].include?(d["type"].split(",").first) rescue nil }
  end

  def unpaid_credit_defaults
    unpaid_defaults.select{|d| ["Telecommunication Service", "Utilities"].exclude?(d["type"].split(",").first) rescue nil }
  end

  def unpaid_non_credit_defaults_total
    unpaid_defaults.select{|d| ["Telecommunication Service", "Utilities"].include?(d["type"].split(",").first) rescue nil }.collect{|d| d[:current_amount].to_f}.sum
  end

  def unpaid_credit_defaults_total
    unpaid_defaults.select{|d| ["Telecommunication Service", "Utilities"].exclude?(d["type"].split(",").first) rescue nil }.collect{|d| d[:current_amount].to_f}.sum
  end

  def credit_clearouts_total
    credit_clearouts.collect{|d| d[:current_amount].to_f}.sum
  end

  def non_credit_clearouts_total
    non_credit_clearouts.collect{|d| d[:current_amount].to_f}.sum
  end

  def paid_court_actions
    court_actions.select{|ca| "P" == ca["status_code"] rescue nil }
  end

  def not_paid_court_actions
    court_actions.select{|ca| "P" != ca["status_code"] rescue nil }
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
    defaults_array = []
    [hsh].flatten.each do |default|
      tmp_hash = {"section" => "Default",
                  "type" => [(default["account_details"]["account_type"] rescue nil),
                             (default["account_details"]["default_status"] rescue nil),
                             (default["original_default"]["reason_to_report"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (default["original_default"]["date_recorded"] rescue nil),
                  "creditor" => (default["original_default"]["credit_provider"] rescue nil),
                  "current_amount" => (default["current_default"]["default_amount"] rescue nil),
                  "original_amount" => (default["original_default"]["default_amount"] rescue nil),
                  "role" => (default["account_details"]["role"]["code"] rescue nil),
                  "reference" => (default["account_details"]["client_reference"] rescue nil),
                  "status_date" => (default["account_details"]["default_status"]["date"] rescue nil),
                  "status_code" => (default["account_details"]["default_status"]["code"] rescue nil)}
      defaults_array << tmp_hash.with_indifferent_access
    end
    defaults_array
  end

  def commercial_defaults
    return [] unless (primary_match["individual_commercial_credit_file"]["default"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_commercial_credit_file"]["default"]))
    defaults_array = []
    [hsh].flatten.each do |default|
      tmp_hash = {"section" => "Default",
                  "type" => [(default["account_details"]["account_type"] rescue nil),
                             (default["account_details"]["default_status"] rescue nil),
                             (default["original_default"]["reason_to_report"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (default["original_default"]["date_recorded"] rescue nil),
                  "creditor" => (default["original_default"]["credit_provider"] rescue nil),
                  "current_amount" => (default["current_default"]["default_amount"] rescue nil),
                  "original_amount" => (default["original_default"]["default_amount"] rescue nil),
                  "role" => (default["account_details"]["role"]["code"] rescue nil),
                  "reference" => (default["account_details"]["client_reference"] rescue nil)}
      defaults_array << tmp_hash
    end
    defaults_array
  end

  def credit_enquiries
    return [] unless (primary_match["individual_consumer_credit_file"]["credit_enquiry"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["credit_enquiry"]))
    [hsh].flatten.each do |cred|
      cred["role"] = cred["role"]["code"] rescue nil
    end
    [hsh].flatten
  end

  def commercial_credit_enquiries
    return [] unless (primary_match["individual_commercial_credit_file"]["credit_enquiry"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_commercial_credit_file"]["credit_enquiry"]))
    [hsh].flatten.each do |cred|
      cred["role"] = cred["role"]["code"] rescue nil
    end
    [hsh].flatten
  end

  def court_actions
    return [] unless (primary_match["individual_public_data_file"]["court_action"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["court_action"]))
    court_action_array = []
    [hsh].flatten.each do |ca|
      tmp_hash = {"section" => "Court Action",
                  "type" => [(ca["type"].gsub('-', ' ').humanize rescue nil),
                             (ca["court_type"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (ca["action_date"] rescue nil),
                  "creditor" => (ca["creditor"] rescue nil),
                  "court_action_amount" => (ca["court_action_amount"].to_i rescue nil),
                  "role" => (ca["role"]["code"] rescue nil),
                  "reference" => (ca["plaint_number"] rescue nil),
                  "status_date" => (ca["court_action_status"]["date"] rescue nil),
                  "status_code" => (ca["court_action_status"]["code"] rescue nil)}
      court_action_array << tmp_hash
    end
    court_action_array
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

  def proprietorships
    return [] unless (primary_match["individual_public_data_file"]["proprietorship"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["proprietorship"]))
    [hsh].flatten.each do |el|
      el["business_bureau_reference"] = el["business"]["bureau_reference"] rescue nil
      el["business_name"] = el["business"]["business_name"] rescue nil
      el["business_registration_state"] = el["business"]["business_registration"]["state"] rescue nil
      el["business_registration_number"] = el["business"]["business_registration"]["number"] rescue nil
      el.delete("business")
    end
    [hsh].flatten
  end

  def bankruptcies
    return [] unless (primary_match["individual_public_data_file"]["bankruptcy"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_public_data_file"]["bankruptcy"]))
    bankrupt_array = []
    [hsh].flatten.each do |bnkr|
      tmp_hash = {"section" => "Bankruptcy",
                  "type" => [(bnkr["bankruptcy_type"] rescue nil),
                             (bnkr["proceedings"]["proceedings_status"]["code"] rescue nil)].reject(&:blank?).join(','),
                  "date" => (bnkr["date_declared"] rescue nil),
                  "role" => (bnkr["role"]["code"] rescue nil),
                  "discharge_date" => (bnkr["discharge_status"]["date"] rescue nil),
                  "discharge_status" => (( bnkr["discharge_status"]["type"] || bnkr["discharge_status"]["code"] ) rescue nil)}
      bankrupt_array << tmp_hash
    end
    bankrupt_array
  end

  def cross_references
    return [] unless (primary_match["individual_consumer_credit_file"]["individual_cross_reference"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual_consumer_credit_file"]["individual_cross_reference"]))
    [hsh].flatten.each do |el|
      el["individual"] = [(el["individual_name"]["first_given_name"] rescue nil), (el["individual_name"]["other_given_name"] rescue nil), (el["individual_name"]["family_name"] rescue nil)].reject(&:blank?).join(' ')
      el.delete("individual_name")
    end
    [hsh].flatten
  end

  def employment_histories
    return [] unless (primary_match["individual"]["employment"] rescue false)
    hsh = Marshal.load(Marshal.dump(primary_match["individual"]["employment"]))
    [hsh].flatten
  end

  def number_of_paid_defaults
    summary_data["defaults_paid"].to_i
  end

  def number_of_unpaid_defaults
    summary_data["defaults"].to_i - summary_data["defaults_paid"].to_i
  end

  def paid_credit_provider_defaults
    summary_data["defaults"].to_i - summary_data["telco_and_utility_defaults"].to_i
  end

  def age_of_latest_default_in_months
    # defaults.any? ? summary_data["time_since_last_default"].to_i : "no_defaults"
    defaults.any? ? number_of_months(defaults.first["date"]) : "no_defaults"
  end

  def age_of_latest_unpaid_default_in_months
    unpaid_defaults.any? ? number_of_months(unpaid_defaults.first["date"]) : "no_defaults"
  end

  def age_of_latest_unpaid_credit_default_in_months
    unpaid_credit_default.any? ? number_of_months(unpaid_credit_default.first["date"]) : "no_defaults"
  end

  def age_of_latest_paid_default_in_months
    paid_defaults.any? ? number_of_months(paid_defaults.first["date"]) : "no_defaults"
  end

  def age_of_latest_credit_default_in_months
    credit_defaults.any? ? number_of_months(credit_defaults.first["date"]) : "no_defaults"
  end

  def age_of_latest_discharged_bankruptcy_in_months
    discharges = bankruptcies.map do |bankruptcy|
      bankruptcy if (bankruptcy["discharge_status"] == "discharged")
    end.compact
    discharges.any? ? number_of_months(discharges.first["discharge_date"]) : "no_bankruptcies"
  end

  def number_of_enquiries_in_last_3_months
    summary_data["credit_enquiries_3"].to_i
  end

  def number_of_enquiries_in_last_24_months
    count = 0
    credit_enquiries.each do |enquiry|
      count += 1 if ((Date.today.year - enquiry["enquiry_date"].to_date.year) < 2)
    end
    count
  end

  def bankrupt?
    (bankruptcies.first["discharge_status"] != "discharged") rescue false
  end

  def part_ix_or_x_bankrupt?
    bs = part_ix_bankruptcies + part_x_bankruptcies
    (bs.first["discharge_status"] != "discharged") rescue false
  end

  def earliest_bankruptcy_date
    bankruptcies.map{|d| d["date"].to_date}.compact.min rescue nil
  end

  def latest_discharged_bankruptcy_date
    discharges = bankruptcies.map do |bankruptcy|
      bankruptcy if (bankruptcy["discharge_status"] == "discharged")
    end.compact
    discharges.any? ? (discharges.first["discharge_date"].to_date rescue nil) : nil
  end

  # All defaults
  def latest_default_date
    defaults.map{|d| d["date"].to_date}.compact.max rescue nil
  end

  def subsequent_defaults
    if bankruptcies.any? && !bankrupt? && ((latest_default_date > latest_discharged_bankruptcy_date) rescue nil)
      latest_default_date
    else
      nil
    end
  end

  # Credit defaults
  def latest_credit_default_date
    defaults.reject {|d| ["Telecommunication Service", "Utilities"].include?(d[:account_type]) }.map{|d| d["date"].to_date}.compact.max rescue nil
  end

  def subsequent_credit_defaults
    if bankruptcies.any? && !bankrupt? && ((latest_credit_default_date > latest_discharged_bankruptcy_date) rescue nil)
      latest_credit_default_date
    else
      nil
    end
  end

  # Non-credit defaults
  def latest_non_credit_default_date
    defaults.select {|d| ["Telecommunication Service", "Utilities"].include?(d[:account_type]) }.map{|d| d["date"].to_date}.compact.max rescue nil
  end

  def subsequent_non_credit_defaults
    if bankruptcies.any? && !bankrupt? && ((latest_non_credit_default_date > latest_discharged_bankruptcy_date) rescue nil)
      latest_non_credit_default_date
    else
      nil
    end
  end

  def subsequent_part_ix_or_part_x_bankruptcies
    bs = part_x_bankruptcies + part_ix_bankruptcies
    ret = bs.map do |bankruptcy|
      bankruptcy["date"].to_date if ((bankruptcy["date"].to_date > earliest_bankruptcy_date) rescue nil)
    end
    ret.any? ? ret.max : nil
  end

  def part_x_bankruptcies
    self.bankruptcies.select{|x| x["type"] =~ /Personal Insolvency Agreement (Part 10 Deed)/ || x["type"] =~ /Part 10/ || x["type"] =~ /part 10/}.compact
  end

  def part_ix_bankruptcies
    self.bankruptcies.select{|x| x["type"] =~ /Debt Agreement (Part 9)/ || x["type"] =~ /Part 9/ || x["type"] =~ /part 9/ }.compact
  end

  def external_administration
    self.summary_data["external_administration_director"].to_i > 0 rescue false
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

  def number_of_months(from_date)
    from_date = from_date.to_date
    now = Date.today
    (now.year * 12 + now.month)  - (from_date.year * 12 + from_date.month)
  end

end
