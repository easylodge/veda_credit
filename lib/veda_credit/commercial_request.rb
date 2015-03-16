class VedaCredit::CommercialRequest < ActiveRecord::Base
  self.table_name = "veda_credit_commercial_requests"
  
  has_one :commercial_response, dependent: :destroy

  serialize :access
  serialize :service
  serialize :entity
  serialize :enquiry
 
  validates :ref_id, presence: true 
  validates :access, presence: true
  validates :service, presence: true
  validates :entity, presence: true
  validates :enquiry, presence: true

  before_save :to_xml_body

  def to_xml_body
    if self.access && self.service && self.enquiry
      
      url = self.access[:url]
      username = self.access[:username] 
      password = self.access[:password]
      
      acn = self.entity[:acn]
      
      client_ref = self.ref_id
      role = self.enquiry[:role]
      amount = self.enquiry[:enquiry_amount]
      currency = self.enquiry[:currency_code] || "AUD"
      bureau_reference = self.enquiry[:bureau_reference]
      enquiry_id = self.enquiry[:enquiry_id] || ""
      request_type = self.enquiry[:request_type] || "REPORT"
      enquiry_type = self.enquiry[:enquiry_type] || "credit-enquiry" #credit-enquiry, credit-review
      reason_for_enquiry = self.enquiry[:reason_for_enquiry]
      cur_and_hist = self.enquiry[:current_and_history] || "current"
      scoring = self.enquiry[:scoring_required] || "no"
      enrichment = self.enquiry[:enrichment_required] || "no"
      ppsr = self.enquiry[:ppsr_required] || "no"
      credit_type = self.enquiry[:credit_type] || "COMMERCIAL"
      account_type = self.enquiry[:account_type] #HC
      account_type_code = self.enquiry[:account_type_code] #HIREPURCHASE
      link_limit = self.enquiry[:link_limit] || 0 #100
      
      
      soap_xml = 
                  "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:com=\"http://vedaxml.com/vxml2/company-enquiry-v3-2.xsd\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
                     <soapenv:Header>
                        <wsse:Security mustUnderstand=\"1\" xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\">
                           <wsse:UsernameToken>
                              <wsse:Username>#{username}</wsse:Username>
                              <wsse:Password>#{password}</wsse:Password>
                           </wsse:UsernameToken>
                        </wsse:Security>
                        <wsa:MessageID>urn:example.com:123456789</wsa:MessageID>
                        <wsa:To>https://vedaxml.com/sys2/company-enquiry-v3-2</wsa:To>
                        <wsa:Action>http://vedaxml.com/companyEnquiry/ServiceRequest</wsa:Action>
                     </soapenv:Header>
                     <soapenv:Body>
                        <com:request client-reference=\"#{client_ref}\" reason-for-enquiry=\"#{reason_for_enquiry}\" enquiry-id=\"#{enquiry_id}\" request-type=\"#{request_type}\" >
                           <!--You have a CHOICE of the next 2 items at this level-->
                           <!--Optional:-->
                           <com:bureau-reference>#{bureau_reference}</com:bureau-reference>
                           <!--1 or more repetitions:-->
                           <com:subject role=\"#{role}\">
                              <com:australian-company-number>#{acn}</com:australian-company-number>
                              <!--0 to 20 repetitions:-->
                           </com:subject>
                           <com:current-historic-flag>#{cur_and_hist}</com:current-historic-flag>
                           <com:enquiry type=\"#{enquiry_type}\">
                              <com:account-type code=\"#{account_type_code}\">#{account_type}</com:account-type>
                              <com:enquiry-amount currency-code=\"#{currency}\">#{amount}</com:enquiry-amount>
                              <!--Optional:-->
                              <com:co-borrower/>
                              <!--Optional:-->
                              <com:client-reference>#{client_ref}</com:client-reference>
                           </com:enquiry>

                           <com:collateral-information>
                              <com:credit-type>#{credit_type}</com:credit-type>
                              <!--Optional:-->
                              <com:link-limit>#{link_limit}</com:link-limit>
                              <com:scoring-required>#{scoring}</com:scoring-required>
                              <!--Optional:-->
                              <com:enrichment-required>#{enrichment}</com:enrichment-required>
                              <!--Optional:-->
                              <com:ppsr-required>#{ppsr}</com:ppsr-required>
                           </com:collateral-information>
                        </com:request>
                     </soapenv:Body>
                  </soapenv:Envelope>"
      self.xml = soap_xml
    else
      "Requires access, service or enquiry hash"
    end
  end

  def validate_xml
    xsd = Nokogiri::XML::Schema(self.schema)
    doc = Nokogiri::XML(self.xml).remove_namespaces!
    # xsd.validate(doc.xpath("//com").to_s).each do |error|
    xsd.validate(doc).each do |error|
      error.message
    end     
  end

  def schema
    fname = File.expand_path('../../lib/assets/company-enquiry-3-2-1.xsd', File.dirname(__FILE__) )
    File.read(fname)
  end
  
	def post
    if self.access
			headers = {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
      HTTParty.post(self.access[:url], :body => to_xml_body, :headers => headers)
	  else
      "No access hash!"
    end
  end

  def to_s
    "Veda Credit Commercial Request"
  end

 
end
