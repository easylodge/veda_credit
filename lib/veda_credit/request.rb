module VedaCredit
	class Request < ActiveRecord::Base
    self.table_name = "veda_credit_requests"
    self.primary_key = :id

    has_one :response, dependent: :destroy

    serialize :access
    serialize :product
    serialize :entity
    serialize :enquiry
    serialize :struct

    validates :access, presence: true
    validates :product, presence: true
    validates :entity, presence: true
    validates :enquiry, presence: true

    after_initialize :to_xml!, :to_struct!

    
    def self.access
      if !defined?(Rails).nil?
        rails_config = YAML.load_file('config/veda_config.yml')
        access = {
          :url => rails_config["url"],
          :access_code => rails_config["access_code"],
          :password => rails_config["password"],
          :subscriber_id => rails_config["subscriber_id"],
          :security_code => rails_config["security_code"],
          :request_mode => rails_config["request_mode"] 
        }
        if access[:access_code].nil?
          "Fill in your veda details in 'config/veda_config.yml"
        else
          access
        end

      elsif defined?(Rails).nil?
        if File.read('dev_veda_access.yml')
          dev_config = YAML.load_file('dev_veda_access.yml')
          access = {
            :url => dev_config["url"],
            :access_code => dev_config["access_code"],
            :password => dev_config["password"],
            :subscriber_id => dev_config["subscriber_id"],
            :security_code => dev_config["security_code"],
            :request_mode => dev_config["request_mode"]
          }
        else
          "Create 'dev_details_access.yml' in project root with:
            url: 'https://ctaau.vedaxml.com/cta/sys1'
            access_code: 'your details'
            password: 'your details'
            subscriber_id: 'your details'
            security_code: 'your details'
            request_mode: 'test'
          "
        end   
      end
    end  

    def to_hash!
      if self.xml
        Hash.from_xml(self.xml)
      end
    end

    def to_struct!
      if self.xml
        self.struct = RecursiveOpenStruct.new(self.to_hash!["BCAmessage"])
      end
    end

    def to_xml!

      if self.access && self.product && self.entity && self.enquiry
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
    							mes.send(:"individual"){
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
      else
        "Require correct input"
      end
		end

		def post
			auth = {:username => self.access[:access_code], :password => self.access[:password] }
			base_uri = self.access[:url]
			body = self.xml
      headers = {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
			HTTParty.post(base_uri, :body => body, :basic_auth => auth, :headers => headers)
		end

    def validate_xml
      xsd = Nokogiri::XML::Schema(self.schema)
      doc = Nokogiri::XML(self.xml)
      xsd.validate(doc).each do |error|
        error.message
      end     

    end

 		def schema
			fname = File.expand_path(File.dirname(__FILE__) + '/Vedascore-individual-enquiries-request-version-1.1.xsd')
			File.read(fname)
		end

		
	end
end