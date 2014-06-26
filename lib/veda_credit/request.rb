class VedaCredit::Request < ActiveRecord::Base
  self.table_name = "veda_credit_requests"
  
  has_one :response, dependent: :destroy

  serialize :access
  serialize :product
  serialize :entity
  serialize :enquiry
 
  validates :access, presence: true
  validates :product, presence: true
  validates :entity, presence: true
  validates :enquiry, presence: true

  after_initialize :to_xml_body

  def to_xml_body
    if self.access && self.product && self.enquiry
      if self.bureau_reference
        self.to_bureau_reference
      elsif self.entity
        self.to_individual
      end
    else
      "Requires access, product or enquiry hash"
    end
  end

  def to_individual
		builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
			xml.BCAmessage "type" => "REQUEST" do |mes|
				mes.BCAaccess {
					mes.send(:"BCAaccess-code", self.access[:access_code])
					mes.send(:"BCAaccess-pwd", self.access[:password])
				}
				mes.BCAservice {
					mes.send(:"BCAservice-client-ref", self.enquiry[:client_reference])
					mes.send(:"BCAservice-code", self.product[:service_code])
					mes.send(:"BCAservice-code-version", self.product[:service_code_version])		
					mes.send(:"BCAservice-data") { 
						mes.send(:"request", "version" => self.product[:request_version], "mode" => self.access[:request_mode]){
							mes.send(:"subscriber-details"){
								mes.send(:"subscriber-identifier", self.access[:subscriber_id])
								mes.send(:"security", self.access[:security_code])
							}
							mes.send(:"product", "name" => self.product[:product_name], "summary" => self.product[:summary])
							mes.send(:"individual", "role" => self.enquiry[:role]){
								mes.send(:"individual-name"){
									mes.send(:"family-name", self.entity[:family_name])
									mes.send(:"first-given-name", self.entity[:first_given_name])
                  mes.send(:"other-given-name", self.entity[:other_given_name])
								}
								mes.send(:"employment") {
									mes.send(:"employer", self.entity[:employer])
								}
								mes.send(:"address", "type" => self.entity[:address_type]) {
									mes.send(:"unit-number", self.entity[:unit_number])
                  mes.send(:"street-number", self.entity[:street_number])
                  mes.send(:"property", self.entity[:property])
									mes.send(:"street-name", self.entity[:street_name])
                  mes.send(:"street-type", "code" => self.entity[:street_type])
									mes.send(:"suburb", self.entity[:suburb])
                  mes.send(:"state", self.entity[:state])
                  mes.send(:"postcode", self.entity[:postcode])
                  mes.send(:"country", "country-code" => self.entity[:country_code])
                }
                mes.send(:"drivers-licence-number", self.entity[:drivers_licence_number])
								mes.send(:"gender", "type" => self.entity[:gender_type])
                mes.send(:"date-of-birth", self.entity[:date_of_birth])
							}
							mes.send(:"enquiry", "type" => self.enquiry[:enquiry_type]) {
								mes.send(:"account-type", "code" => self.enquiry[:account_type_code])
								mes.send(:"enquiry-amount", self.enquiry[:enquiry_amount], "currency-code" => self.enquiry[:currency_code])
								mes.send(:"client-reference", self.enquiry[:client_reference])
							}
						}
					}
				}
			end
		end
		self.xml = builder.to_xml
  end

  def to_bureau_reference
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.BCAmessage "type" => "REQUEST" do |mes|
        mes.BCAaccess {
          mes.send(:"BCAaccess-code", self.access[:access_code])
          mes.send(:"BCAaccess-pwd", self.access[:password])
        }
        mes.BCAservice {
          mes.send(:"BCAservice-client-ref", self.enquiry[:client_reference])
          mes.send(:"BCAservice-code", self.product[:service_code])
          mes.send(:"BCAservice-code-version", self.product[:service_code_version])   
          mes.send(:"BCAservice-data") { 
            mes.send(:"request", "version" => self.product[:request_version], "mode" => self.access[:request_mode]){
              mes.send(:"subscriber-details"){
                mes.send(:"subscriber-identifier", self.access[:subscriber_id])
                mes.send(:"security", self.access[:security_code])
              }
              mes.send(:"product", "name" => self.product[:product_name], "summary" => self.product[:summary])
              mes.send(:"bureau-reference", self.bureau_reference, "role" => self.enquiry[:role]) 
              mes.send(:"enquiry", "type" => self.enquiry[:enquiry_type]) {
                mes.send(:"account-type", "code" => self.enquiry[:account_type_code])
                mes.send(:"enquiry-amount", self.enquiry[:enquiry_amount], "currency-code" => self.enquiry[:currency_code])
                mes.send(:"client-reference", self.enquiry[:client_reference])
              }
            }
          }
        }
      end
    end
    self.xml = builder.to_xml
  end

	def post
    if self.access
			auth = {:username => self.access[:access_code], :password => self.access[:password] }
			base_uri = self.access[:url]
			body = self.xml
      headers = {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
			HTTParty.post(base_uri, :body => body, :basic_auth => auth, :headers => headers)
	  else
      "No access hash!"
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
		fname = File.expand_path('../../lib/assets/Vedascore-individual-enquiries-request-version-1.1.xsd', File.dirname(__FILE__) )
		File.read(fname)
	end

	
end
