class VedaCredit::CommercialResponse < ActiveRecord::Base
  self.table_name = "veda_credit_commercial_responses"
  
  belongs_to :commercial_request, dependent: :destroy

  serialize :headers
  
  validates :commercial_request_id, presence: true
  validates :xml, presence: true

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
      hsh = [hsh]
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
  
  def age_of_file
    create_date = get_hash("file-creation-date")["file_creation_date"]
    return nil unless create_date.present?
    now = DateTime.now
    create_date = create_date.to_date
    (now.year * 12 + now.month) - (create_date.year * 12 + create_date.month)
  end

  def summary_data
    doc = Nokogiri::XML(self.xml)
    hash = {}
      doc.remove_namespaces!
    doc.xpath("//summary-entry").each do |el|
      hash[el.children.children[0].text.underscore] = el.children.children[1].text.to_i 
    end
    hash["age_of_file"] = age_of_file
    hash
  end
  
  # def summary_data
  #   hsh = get_hash("summary-data")
  #   return {} unless hsh.present?
  #   summary = {}
  #   if hsh["summary_data"]["summary_entry"].is_a?(Array)
  #     hsh["summary_data"]["summary_entry"].each do |sum|
  #       key = sum["summary_name"].underscore
  #       value = sum["summary_value"]
  #       summary[key] = value.to_i
  #     end
  #   else
  #     summary[hsh["summary_name"].underscore] = hsh["summary_value"].to_i
  #   end
  #   copied_sum = Marshal.load(Marshal.dump(summary))
  #   copied_sum
  # end

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
      messages = [hsh["narrative"]]
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
        director["place_of_birth"] = [(director["birth_details"]["birth_locality"] rescue nil), (director["birth_details"]["birth_state"] rescue nil)].join(' ')
        address_line_1 = [(director["address"]["street_number"] rescue nil), (director["address"]["street_name"] rescue nil), (director["address"]["street_type"] rescue nil)].join(' ')
        address_line_2 = [(director["address"]["suburb"] rescue nil), (director["address"]["state"] rescue nil), (director["address"]["postcode"] rescue nil)].join(' ')
        director["address"] = [address_line_1, address_line_2].join(', ')
      end
    else
      first_names = [(hsh["individual_name"]["first_given_name"] rescue nil), (hsh["individual_name"]["other_given_name"] rescue nil)].join(' ')
      surname = hsh["individual_name"]["family_name"] rescue nil
      hsh["director_name"] = [surname, first_names].join(', ')
      hsh["place_of_birth"] = [(hsh["birth_details"]["birth_locality"] rescue nil), (hsh["birth_details"]["birth_state"] rescue nil)].join(' ')
      address_line_1 = [(hsh["address"]["street_number"] rescue nil), (hsh["address"]["street_name"] rescue nil), (hsh["address"]["street_type"] rescue nil)].join(' ')
      address_line_2 = [(hsh["address"]["suburb"] rescue nil), (hsh["address"]["state"] rescue nil), (hsh["address"]["postcode"] rescue nil)].join(' ')
      hsh["address"] = [address_line_1, address_line_2].join(', ')
      hsh = [hsh]
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
      hsh = [hsh]
    end
    hsh
  end

  def error
    if self.xml.include?("<html>")
      body = /<body>([\s\S]*)<\/body>/.match(self.xml)[0]
      body.gsub!(/<body>|<h1>|<h3>/, " ").gsub!(/<\/body>|<\/h1>|<\/h3>/, '').gsub!("\n", '').strip!
      body
    else
      hsh = get_hash("error")
      return {} unless hsh.present?
      "Error: #{hsh["error"]["code"]} - #{hsh["error"]["description"]}"
    end
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
