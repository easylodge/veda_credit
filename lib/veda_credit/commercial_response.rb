class VedaCredit::CommercialResponse < ActiveRecord::Base
  self.table_name = "veda_credit_commercial_responses"
  
  belongs_to :commercial_request, dependent: :destroy

  serialize :headers
  # serialize :as_hash
  
  validates :commercial_request_id, presence: true
  validates :xml, presence: true
  # validates :headers, presence: true
  # validates :code, presence: true
  # validates :success, presence: true

  # before_save :to_hash
  
  # def to_hash
  #   hash = Hash.from_xml(self.xml)
  #   doc = Nokogiri::XML(self.xml)
  #   gender_value = (doc.xpath("//gender").first.attributes["type"].value rescue nil)
  #   role_value = (doc.xpath("//role").first.attributes["type"].value rescue nil)
  #   gender = (hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"]["individual"]["gender"] rescue nil)
  #   role = (hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"]["individual_consumer_credit_file"]["credit_enquiry"]["role"] rescue nil)
  #   gender = gender_value if gender
  #   role = role_value if role
  #   hash
  # end

  # def self.nested_hash_value(obj,key)
  #   if obj.respond_to?(:key?) && obj.key?(key)
  #     obj[key]
  #   elsif obj.respond_to?(:each)
  #     r = nil
  #     obj.find{ |*a| r=nested_hash_value(a.last,key) }
  #     r
  #   end
  # end

  # def error
  #   bca_error = VedaCredit::CommercialResponse.nested_hash_value(self.to_hash, "BCAerror")
  #   product_error = VedaCredit::CommercialResponse.nested_hash_value(self.to_hash, "error")
  #   if bca_error
  #     self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["BCAerror"]["BCAerror_description"]
  #   elsif product_error
  #     ("#{product_error["error_type"].humanize} error: #{product_error["input_container"]}, #{product_error["error_description"]}" rescue "There was an Veda product error")
  #   else        
  #     "No Error"
  #   end
  # end

  # def validate_xml
  #   xsd = Nokogiri::XML::Schema(self.schema)
  #   doc = Nokogiri::XML(self.xml)
  #   xsd.validate(doc).each do |error|
  #     error.message
  #   end     
  # end

  # def schema
  #   fname = File.expand_path('../../lib/assets/Vedascore-individual-enquiries-response-version-1.1.xsd', File.dirname(__FILE__) )
  #   File.read(fname)
  # end

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
    "Veda Credit Commercial Response"
  end

  ##NEW COMMERCIAL HELPERS##
  def credit_enquiries
    hsh = get_hash("credit-enquiry-list")
    return {} unless hsh.present?
    hsh = hsh["credit_enquiry_list"].delete("credit_enquiry")
    if hsh.is_a?(Array)
      hsh.each do |cred|
        cred["enquiry_date"] = cred["enquiry_date"].to_date rescue nil
        cred["credit_enquirer"] = cred.delete("enquirer") rescue nil
        cred["reference_number"] = cred.delete("ref_number") rescue nil
        cred["amount"] = cred["amount"].to_i rescue nil
        cred["account_type_code"] = cred["account_type"]["code"] rescue nil
        cred["account_type"] = cred["account_type"]["type"] rescue nil
        cred["role_in_enquiry"] = cred["role"]["type"] rescue nil
        cred.delete("role")
      end
    else
      hsh["enquiry_date"] = hsh["enquiry_date"].to_date rescue nil
      hsh["credit_enquirer"] = hsh.delete("enquirer") rescue nil
      hsh["reference_number"] = hsh.delete("ref_number") rescue nil
      hsh["amount"] = hsh["amount"].to_i rescue nil
      hsh["account_type_code"] = hsh["account_type"]["code"] rescue nil
      hsh["account_type"] = hsh["account_type"]["type"] rescue nil
      hsh["role_in_enquiry"] = hsh["role"]["type"] rescue nil
      hsh.delete("role")
    end
    hsh
  end

  def company_enquiry_header
    hsh = get_hash("organisation-report-header")
    return {} unless hsh.present?
    hsh = hsh.delete("organisation_report_header")
    hsh["asic_extract_date"] = hsh["extract_date"]["asic_extract_date"] rescue nil
    hsh.delete("extract_date")
    hsh["report_created"] = hsh.delete("report_create_date")
    hsh
  end

  def summary_data
    hsh = get_hash("summary-data")
    return {} unless hsh.present?
    summary = {}
    if hsh["summary_data"]["summary_entry"].is_a?(Array)
      hsh["summary_data"]["summary_entry"].each do |sum|
        key = sum["summary_name"].underscore
        value = sum["summary_value"]
        summary[key] = value
      end
    else
      summary[hsh["summary_name"]] = hsh["summary_value"]
    end
    summary
  end

  def file_messages
    hsh = get_hash("organisation-legal")
    return {} unless hsh.present?
    hsh = hsh["organisation_legal"]["file_message_list"]["file_message"] rescue {}
    if hsh.is_a?(Array)
      messages = []
      hsh.each do |mes|
        messages << mes["narrative"]
      end
    else
      messages = hsh["narrative"]
    end
    messages
  end

  def company_identity
    hsh = get_hash("company-identity")
    return {} unless hsh.present?
    hsh = hsh["company_identity"]
    hsh.delete("previous_name")
    if hsh["registered_office"]
      address_line_1 = hsh["registered_office"]["address_lines"]["street_details"] rescue nil
      address_line_2 = [(hsh["registered_office"]["address_lines"]["locality_details"] rescue nil), (hsh["registered_office"]["address_lines"]["state"] rescue nil), (hsh["registered_office"]["address_lines"]["postcode"] rescue nil)].join(' ')
      hsh["registered_office"]["address"] = [address_line_1, address_line_2].join(', ')
    end
    if hsh["principal_place_of_business"]
      address_line_1 = hsh["principal_place_of_business"]["address_lines"]["street_details"] rescue nil
      address_line_2 = [(hsh["principal_place_of_business"]["address_lines"]["locality_details"] rescue nil), (hsh["principal_place_of_business"]["address_lines"]["state"] rescue nil), (hsh["principal_place_of_business"]["address_lines"]["postcode"] rescue nil)].join(' ')
      hsh["principal_place_of_business"]["address"] = [address_line_1, address_line_2].join(', ')
    end
    hsh
  end

  def directors
    hsh = get_hash("directors-list")
    return {} unless hsh.present?
    hsh = hsh["directors_list"]["directors"]
    if hsh.is_a?(Array)
      hsh.each do |director|
        first_names = [(director["individual_name"]["first_given_name"] rescue nil), (director["individual_name"]["other_given_name"] rescue nil)].join(' ')
        surname = director["individual_name"]["family_name"] rescue nil
        director["director_name"] = [surname, first_names].join(', ')
        director["place_of_birth"] = [director["birth_details"]["birth_locality"], director["birth_details"]["birth_state"]].join(' ')
        address_line_1 = [(director["address"]["street_number"] rescue nil), (director["address"]["street_name"] rescue nil), (director["address"]["street_type"] rescue nil)].join(' ')
        address_line_2 = [(director["address"]["suburb"] rescue nil), (director["address"]["state"] rescue nil), (director["address"]["postcode"] rescue nil)].join(' ')
        director["address"] = [address_line_1, address_line_2].join(', ')
      end
    else
      first_names = [(hsh["individual_name"]["first_given_name"] rescue nil), (hsh["individual_name"]["other_given_name"] rescue nil)].join(' ')
      surname = hsh["individual_name"]["family_name"] rescue nil
      hsh["director_name"] = [surname, first_names].join(', ')
      hsh["place_of_birth"] = [hsh["birth_details"]["birth_locality"], hsh["birth_details"]["birth_state"]].join(' ')
      address_line_1 = [(hsh["address"]["street_number"] rescue nil), (hsh["address"]["street_name"] rescue nil), (hsh["address"]["street_type"] rescue nil)].join(' ')
      address_line_2 = [(hsh["address"]["suburb"] rescue nil), (hsh["address"]["state"] rescue nil), (hsh["address"]["postcode"] rescue nil)].join(' ')
      hsh["address"] = [address_line_1, address_line_2].join(', ')
    end
    hsh
  end

  def secretaries
    hsh = get_hash("secretary-list")
    return {} unless hsh.present?
    hsh = hsh["secretary_list"]["secretaries"] rescue nil
    if hsh.is_a?(Array)
      hsh.each do |secretary|
        first_names = [(secretary["individual_officer"]["individual_name"]["first_given_name"] rescue nil), (secretary["individual_officer"]["individual_name"]["other_given_name"] rescue nil)].join(' ')
        surname = secretary["individual_officer"]["individual_name"]["family_name"] rescue nil
        secretary["secretary_name"] = [surname, first_names].join(', ')
        secretary["place_of_birth"] = [(secretary["birth_details"]["birth_locality"] rescue nil), (secretary["birth_details"]["birth_state"] rescue nil)].join(' ')
        address_line_1 = secretary["address_lines"]["street_details"] rescue nil
        address_line_2 = [(secretary["address_lines"]["locality_details"] rescue nil), (secretary["address_lines"]["state"] rescue nil), (secretary["address_lines"]["postcode"] rescue nil)].join(' ')
        secretary["address"] = [address_line_1, address_line_2].join(', ')
      end
    else
      first_names = [(hsh["individual_officer"]["individual_name"]["first_given_name"] rescue nil), (hsh["individual_officer"]["individual_name"]["other_given_name"] rescue nil)].join(' ')
      surname = hsh["individual_officer"]["individual_name"]["family_name"] rescue nil
      hsh["secretary_name"] = [surname, first_names].join(', ')
      hsh["place_of_birth"] = [(hsh["individual_officer"]["birth_details"]["birth_locality"] rescue nil), (hsh["individual_officer"]["birth_details"]["birth_state"] rescue nil)].join(' ')
      address_line_1 = hsh["address_lines"]["street_details"] rescue nil
      address_line_2 = [(hsh["address_lines"]["locality_details"] rescue nil), (hsh["address_lines"]["state"] rescue nil), (hsh["address_lines"]["postcode"] rescue nil)].join(' ')
      hsh["address"] = [address_line_1, address_line_2].join(', ')
    end
    hsh
  end

  def error
    hsh = get_hash("error")
    return {} unless hsh.present?
    hsh
  end

  private
  def get_hash(search_node=nil)
    doc = Nokogiri::XML(self.xml)
    doc.remove_namespaces!
    node = doc.search("//#{search_node}")
    return {} unless node.present?
    Marshal.load(Marshal.dump(Hash.from_xml(node.to_s)))
  end

end
