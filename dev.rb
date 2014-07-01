# For gem developer/contributor:
# Create file called 'dev_config.yml' in your project root with the following
#
# url: 'https://ctaau.vedaxml.com/cta/sys1'
# access_code: 'your access code'
# password: 'your password'
# subscriber_id: 'your subscriber id'
# security_code: 'your security code'
# request_mode: 'test'
#
# run 'bundle console'and then
# load 'dev.rb' to load this seed data

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:',
  )
require_relative 'spec/schema'


dev_config = YAML.load_file('dev_config.yml')
@veda_url = dev_config["url"]
@access_code = dev_config["access_code"]
@password = dev_config["password"]
@subscriber_id = dev_config["subscriber_id"]
@security_code = dev_config["security_code"]
@request_mode = dev_config["request_mode"]

@access_hash = 
              {
                :url => @veda_url,
                :access_code => @access_code,
                :password => @password,
                :subscriber_id => @subscriber_id,
                :security_code => @security_code,
                :request_mode => @request_mode
                }

@service_hash = 
              {
                :service_code => "VDA001",
                :service_code_version => 'V00',
                :request_version => '1.0',
                
              }

@bca_service_hash = 
              {
                :service_code => "BCA001",
                :service_code_version => 'V00',
                :request_version => '1.0',
                
              }              

@entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :current_address => {
                  :street_name => "Arthur",
                  :suburb => "North Sydney",
                  :state => "NSW"
                },
                :gender_type => 'male'
              }

@enquiry_hash =
              {
                :product_name => "vedascore-financial-consumer-1.1",
                :summary => "yes",  
                :role => 'principal',
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

@business_entity_hash = 
              {
                :business_name => "Martina Johanna Broos",
                :abn => "88130945306",
                :trading_address => {
                  :unit_number=>"3", 
                  :street_number=>"51", 
                  :street_name=>"Australia", 
                  :street_type=>"ST", 
                  :suburb=>"St Marys", 
                  :state=>"NSW", 
                  :postcode=>"2760",
                  :country_code => "AU"
                }
              }

@business_enquiry_hash =
              {
                :product_name => "company-business-broker-dealer-enquiry",
                :summary => "yes",  
                :role => 'principal',
                :enquiry_type => 'broker-dealer',
                :account_type_code => 'HC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }              



@bureau_reference = '186492371'              

@req = VedaCredit::Request.create(access: @access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash)
@post = @req.post
@res = VedaCredit::Response.create(xml: @post.body, headers: @post.header, code: @post.code, success: @post.success?, request_id: @req.id)
@business_req = VedaCredit::Request.create(access: @access_hash, service: @bca_service_hash, entity: @business_entity_hash, enquiry: @business_enquiry_hash)
