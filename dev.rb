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
  adapter: 'sqlite3',
  database: ':memory:'
)
require_relative 'spec/schema'

dev_config = YAML.load_file('dev_config.yml')
@veda_url = dev_config['url']
@access_code = dev_config['access_code']
@password = dev_config['password']
@subscriber_id = dev_config['subscriber_id']
@security_code = dev_config['security_code']
@request_mode = dev_config['request_mode']
@com_url = dev_config['com_url']
@com_username = dev_config['com_username']
@com_password = dev_config['com_password']

@access_hash = {
  url: @veda_url,
  access_code: @access_code,
  password: @password,
  subscriber_id: @subscriber_id,
  security_code: @security_code,
  request_mode: @request_mode
}

@service_hash = {
  service_code: 'VDA001',
  service_code_version: 'V00',
  request_version: '1.0'
}

@bca_service_hash = {
  service_code: 'BCA001',
  service_code_version: 'V00',
  request_version: '1.0'
}

@entity_hash = {
  family_name: 'Verry',
  first_given_name: 'Dore',
  employer: 'Veda',
  current_address: {
    street_name: 'Arthur',
    suburb: 'North Sydney',
    state: 'NSW',
    unformatted_address: '90 Arthur Street North Sydney NSW 2060'
  },
  gender_type: 'male'
}

@enquiry_hash = {
  product_name: 'vedascore-financial-consumer-1.1',
  summary: 'yes',
  role: 'principal',
  enquiry_type: 'credit-application',
  account_type_code: 'LC',
  currency_code: 'AUD',
  enquiry_amount: '5000',
  client_reference: '123456789'
}

# @bca_enquiry_hash = {
#   product_name: 'vedascore-financial-consumer-1.1',
#   summary: 'yes',
#   role: 'principal',
#   enquiry_type: 'credit-application',
#   account_type_code: 'LC',
#   currency_code: 'AUD',
#   enquiry_amount: '5000',
#   client_reference: '123456789'
# }

@business_entity_hash = {
  business_name: 'Martina Johanna Broos',
  abn: '88130945306',
  trading_address: {
    unit_number: '3',
    street_number: '51',
    street_name: 'Australia',
    street_type: 'ST',
    suburb: 'St Marys',
    state: 'NSW',
    postcode: '2760',
    country_code: 'AU'
  }
}

@business_enquiry_hash = {
  product_name: 'company-business-broker-dealer-enquiry',
  summary: 'yes',
  role: 'principal',
  enquiry_type: 'broker-dealer',
  account_type_code: 'HC',
  currency_code: 'AUD',
  enquiry_amount: '5000',
  client_reference: '123456789'
}

@com_enquiry_hash = {
  role: 'principal',
  # enquiry_id: '1223334',
  # enquiry_type: 'credit-review',
  # request_type: 'REPORT',
  account_type_code: 'HC',
  account_type: 'HIREPURCHASE',
  # currency_code: 'AUD',
  enquiry_amount: '5000',
  client_reference: '123456789',
  # current_and_history: 'current',
  # reason_for_enquiry: 'Application',
  # scoring_required: 'no',
  # enrichment_required: 'no',
  # ppsr_required: 'no',
  # credit_type: 'COMMERCIAL'
}

@com_access_hash = {
  url: @com_url,
  username: @com_username,
  password: @com_password
}

@com_service_hash = {
  service_code: 'XML2'
}

@com_entity_hash = {
  acn: '000105233',
  # bureau_reference: 'BFN 001'
}

@bureau_reference = '186492371'

@con_req = VedaCredit::ConsumerRequest.create(ref_id: 123, access: @access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash)
# @con_post = @con_req.post
# @con_res = VedaCredit::ConsumerResponse.create(xml: @con_post.body, consumer_request_id: @con_req.id)
@com_req = VedaCredit::CommercialRequest.create(ref_id: 123, access: @com_access_hash, service: @com_service_hash, entity: @com_entity_hash, enquiry: @com_enquiry_hash)
# @com_post = @com_req.post
# @com_res = VedaCredit::CommercialResponse.create(xml: @com_post.body, commercial_request_id: @com_req.id)
@req = VedaIdmatrix::Request.new(ref_id: 1, access: @access_hash, entity: @entity_hash, enquiry: @enquiry_hash)
@post = @req.post
@res = VedaIdmatrix::Response.create(xml: @post.body, headers: @post.header, code: @post.code, success: @post.success?, request_id: @req.id)
