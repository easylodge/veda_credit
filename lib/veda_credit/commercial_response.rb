class VedaCredit::CommercialResponse < ActiveRecord::Base
  self.table_name = "veda_credit_commercial_responses"

  belongs_to :commercial_request, dependent: :destroy

  serialize :headers

  validates :commercial_request_id, presence: true
  validates :xml, presence: true

  def to_s
    "Veda Credit Commercial Response"
  end

  def credit_enquiries
    hsh = (get_hash("credit-enquiry-list")["credit_enquiry_list"]["credit_enquiry"] rescue nil)
    hsh = [hsh].flatten.compact
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
    hsh
  end

  def company_enquiry_header
    hsh = (get_hash("organisation-report-header")["organisation_report_header"] rescue nil)
    return {} unless hsh.present?
    hsh["asic_extract_date"] = (hsh["extract_date"]["asic_extract_date"] rescue nil)
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
    hash["age_of_file"] = age_of_file if hash.present?
    hash
  end

  def file_messages
    hsh = (get_hash("organisation-legal")["organisation_legal"]["file_message_list"]["file_message"] rescue nil)
    hsh = [hsh].flatten.compact
    messages = []
    hsh.each do |mes|
      messages << mes["narrative"]
    end
    messages
  end

  def writs
    hsh = (get_hash("organisation-legal")["organisation_legal"]["court_writ_list"]["writs"] rescue nil)
    return [] unless hsh.present?
    hsh = [hsh].flatten.compact
    hsh.each do |writ|
      writ["amount"] = writ["amount"].to_f rescue nil
      writ["action_date"] = writ["action_date"].to_date rescue nil
    end
    hsh
  end

  def judgements
    hsh = (get_hash("organisation-legal")["organisation_legal"]["court_judgement_list"]["judgements"] rescue nil)
    return [] unless hsh.present?
    hsh = [hsh].flatten.compact
    hsh.each do |judgement|
      judgement["amount"] = judgement["amount"].to_f rescue nil
      judgement["action_date"] = judgement["action_date"].to_date rescue nil
    end
    hsh
  end

  def petitions
    hsh = (get_hash("organisation-legal")["petition_list"] rescue nil)
    return [] unless hsh.present?
    hsh = [hsh].flatten.compact
    hsh.each do |petition|
      #
    end
    hsh
  end

  def number_of_petitions
    petitions.count rescue 0
  end

  def defaults
    hsh = (get_hash("payment-default-list")["payment_default_list"]["payment_defaults"] rescue nil)
    return [] unless hsh.present?
    hsh = [hsh].flatten.compact
    hsh.each do |default|
      default["amount"] = default["amount"].to_f rescue nil
      default["default_date"] = default["default_date"].to_date rescue nil
      default["original_default_date"] = default["original_default_date"].to_date rescue nil
      default["original_amount"] = default["original_amount"].to_f rescue nil
      default["status_date"] = default["status_date"].to_date rescue nil
    end
    hsh
  end

  def company_identity
    hsh = (get_hash("company-identity")["company_identity"] rescue nil)
    return {} unless hsh.present?
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
    hsh = (get_hash("directors-list")["directors_list"]["directors"] rescue nil)
    hsh = [hsh].flatten.compact
    return [] unless hsh.present?
    hsh.each do |director|
      first_names = [(director["individual_name"]["first_given_name"] rescue nil), (director["individual_name"]["other_given_name"] rescue nil)].join(' ')
      surname = director["individual_name"]["family_name"] rescue nil
      director["director_name"] = [surname, first_names].join(', ')
      director["place_of_birth"] = [(director["birth_details"]["birth_locality"] rescue nil), (director["birth_details"]["birth_state"] rescue nil)].join(' ')
      address_line_1 = [(director["address"]["street_number"] rescue nil), (director["address"]["street_name"] rescue nil), (director["address"]["street_type"] rescue nil)].join(' ')
      address_line_2 = [(director["address"]["suburb"] rescue nil), (director["address"]["state"] rescue nil), (director["address"]["postcode"] rescue nil)].join(' ')
      director["address"] = [address_line_1, address_line_2].join(', ')
    end
    hsh
  end

  def secretaries
    hsh = (get_hash("secretary-list")["secretary_list"]["secretaries"] rescue nil)
    hsh = [hsh].flatten.compact
    return [] unless hsh.present?
    hsh.each do |secretary|
      first_names = [(secretary["individual_officer"]["individual_name"]["first_given_name"] rescue nil), (secretary["individual_officer"]["individual_name"]["other_given_name"] rescue nil)].join(' ')
      surname = secretary["individual_officer"]["individual_name"]["family_name"] rescue nil
      secretary["secretary_name"] = [surname, first_names].join(', ')
      secretary["place_of_birth"] = [(secretary["birth_details"]["birth_locality"] rescue nil), (secretary["birth_details"]["birth_state"] rescue nil)].join(' ')
      address_line_1 = secretary["address_lines"]["street_details"] rescue nil
      address_line_2 = [(secretary["address_lines"]["locality_details"] rescue nil), (secretary["address_lines"]["state"] rescue nil), (secretary["address_lines"]["postcode"] rescue nil)].join(' ')
      secretary["address"] = [address_line_1, address_line_2].join(', ')
    end
    hsh
  end

  def error
    if (self.xml && self.xml.include?("<html>"))
      body = /<body>([\s\S]*)<\/body>/.match(self.xml)[0]
      body.gsub!(/<body>|<h1>|<h3>/, " ").gsub!(/<\/body>|<\/h1>|<\/h3>/, '').gsub!("\n", '').strip!
      body
    elsif get_hash("error").present?
      hsh = get_hash("error")
      "Error: #{hsh["error"]["code"]} - #{hsh["error"]["description"]}"
    elsif get_hash("Fault").present?
      hsh = get_hash("Fault")
      "Error: #{hsh["Fault"]["faultcode"]} - #{hsh["Fault"]["detail"]["policyResult"]["status"]}"
    end
  end

  def success?
    error.nil? ? true : false
  end

  def commercial_service_version
    "New"
  end

  def service_version
    "company-business-enquiry"
  end

  private
  def get_hash(search_node=nil)
    doc = Nokogiri::XML(self.xml)
    doc.remove_namespaces!
    node = doc.search("//#{search_node}")
    return {} unless node.present?
    #5902: sometimes 'node' has multiple file-creation-date elements; return the oldest in this case
    node = node.min{ |a,b| Date.parse(a.children.text) <=> Date.parse(b.children.text)} if node.count > 1
    Marshal.load(Marshal.dump(Hash.from_xml(node.to_s)))
  end

end
