class Equifax::Credit::ConsumerRequest < ActiveRecord::Base
  self.table_name = "equifax_credit_consumer_requests"

  has_one :consumer_response, dependent: :destroy

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
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.send(:"BCAmessage", "type" => "REQUEST") {
          xml.BCAaccess {
            xml.send(:"BCAaccess-code", self.access[:access_code])
            xml.send(:"BCAaccess-pwd", self.access[:password])
          }
          xml.BCAservice {
            xml.send(:"BCAservice-client-ref", self.enquiry[:client_reference])
            xml.send(:"BCAservice-code", self.service[:service_code])
            xml.send(:"BCAservice-code-version", self.service[:service_code_version])
            xml.send(:"BCAservice-data") {
              xml.send(:"request", "version" => self.service[:request_version], "mode" => self.access[:request_mode]){
                xml.send(:"subscriber-details"){
                  xml.send(:"subscriber-identifier", self.access[:subscriber_id])
                  xml.send(:"security", self.access[:security_code])
                }
                xml.send(:"product", "name" => self.enquiry[:product_name], "summary" => self.enquiry[:summary])
                if self.bureau_reference
                  self.to_bureau_reference(xml)
                elsif self.entity && self.individual?
                  self.to_individual(xml)
                elsif self.entity && self.business?
                  self.to_business(xml)
                end
                xml.send(:"enquiry", "type" => self.enquiry[:enquiry_type]) {
                  xml.send(:"account-type", "code" => self.enquiry[:account_type_code])
                  xml.send(:"enquiry-amount", self.enquiry[:enquiry_amount], "currency-code" => self.enquiry[:currency_code])
                  xml.send(:"client-reference", self.ref_id)
                }
              }
            }
          }
        }
      end
      self.xml = builder.to_xml
    else
      "Requires access, service or enquiry hash"
    end
  end

  def individual?
    ["vedascore-financial-commercial-1.1", "vedascore-financial-consumer-1.1", "consumer-enquiry", "commercial-plus-consumer-enquiry", "vedascore-authorized-agent-financial-consumer-plus-commercial-1.1", "vedascore-authorized-agent-financial-commercial-plus-consumer-1.1",
      "vedascore-authorized-agent-financial-consumer-1.1", "vedascore-financial-consumer-plus-commercial-1.1", "vedascore-financial-commercial-plus-consumer-1.1", "vedascore-authorized-agent-financial-commercial-1.1"].include? self.enquiry[:product_name]
  end

  def business?
    ["vedascore-financial-commercial-1.1", "company-business-enquiry", "company-business-broker-dealer-enquiry", "vedascore-financial-commercial-plus-consumer-1.1", "vedascore-authorized-agent-financial-consumer-plus-commercial-1.1",
      "vedascore-authorized-agent-financial-commercial-plus-consumer-1.1", "vedascore-authorized-agent-financial-commercial-1.1"].include? self.enquiry[:product_name]
  end

  def to_individual(xml)
    xml.send(:"individual", "role" => self.enquiry[:role]){
      xml.send(:"individual-name"){
        xml.send(:"family-name", self.entity[:family_name])
        xml.send(:"first-given-name", self.entity[:first_given_name])
        xml.send(:"other-given-name", self.entity[:other_given_name])
      }
      xml.send(:"employment") {
        xml.send(:"employer", self.entity[:employer])
      }
      self.to_address(xml,:current_address) if self.entity[:current_address]
      self.to_address(xml, :previous_address) if self.entity[:previous_address]
      xml.send(:"drivers-licence-number", self.entity[:drivers_licence_number])
      xml.send(:"gender", "type" => self.entity[:gender])
      xml.send(:"date-of-birth", self.entity[:date_of_birth])
    }

  end

  def to_business(xml)
    xml.send(:"business", "role" => self.enquiry[:role]){
      xml.send(:"business-name", self.entity[:business_name])
      xml.send(:"australian-business-number", self.entity[:abn]) unless self.entity[:abn].blank? || self.entity[:abn].size < 11
      self.to_address(xml,:trading_address) if self.entity[:trading_address]
    }

  end

  def to_address(xml,type)
    if type == :previous_address
      address_type = 'residential-previous'
    elsif type == :current_address
      address_type = 'residential-current'
    elsif type == :trading_address
      address_type = 'trading-address'
    end
    if self.entity[type][:unformatted_address]
      xml.send(:"unformatted-address", self.entity[type][:unformatted_address], "type" => address_type)
    else
      xml.send(:"address", "type" => address_type) {
        xml.send(:"unit-number", self.entity[type][:unit_number])
        xml.send(:"street-number", self.entity[type][:street_number])
        xml.send(:"property", self.entity[type][:property]) if self.entity[type][:property]
        xml.send(:"street-name", self.entity[type][:street_name])
        xml.send(:"street-type", "code" => self.entity[type][:street_type])
        xml.send(:"suburb", self.entity[type][:suburb])
        xml.send(:"state", self.entity[type][:state])
        xml.send(:"postcode", self.entity[type][:postcode])
        xml.send(:"country", "country-code" => self.entity[type][:country_code])
      }
    end
  end

  def to_bureau_reference(xml)
    xml.send(:"bureau-reference", self.bureau_reference, "role" => self.enquiry[:role])
  end

	def post
    if self.access
			auth = {:username => self.access[:access_code], :password => self.access[:password] }
			base_uri = self.access[:url]
			body = self.xml
      headers = {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
			HTTParty.post(base_uri, :body => body, :basic_auth => auth, :headers => headers, :timeout => self.access[:timeout])
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

  def to_s
    "Equifax Credit Consumer Request"
  end

end
