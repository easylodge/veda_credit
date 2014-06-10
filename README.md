# Veda

Ruby gem to make requests to Veda Credit service. Website: [https://www.veda.com.au](https://www.veda.com.au/) Saves both requests and responses to db.

## Installation

Add this line to your application's Gemfile:

    gem 'veda'

And then execute:

    $ bundle

Then run install generator:
	
	rails g veda:install

Then run migrations:

	rake db:migrate


## Usage

### Request


    request = Veda::Request.create(access: access_hash, product: product_hash, entity: entity_hash, enquiry: enquiry_hash)

Attributes for access_hash:

    :url
    :access_code
    :password
    :subscriber_id
    :security_code
    :request_mode

Attributes for product_hash:

    :service_code
    :service_code_version
    :request_version
    :product_name
    :summary

Attributes for entity_hash:

    :family_name
    :first_given_name
    :other_given_name
    :employer
    :unit_number
    :street_number
    :property
    :street_name
    :street_type
    :suburb
    :state
    :postcode
    :gender_type
    :drivers_licence_number
    :date_of_birth

Attributes for enquiry_hash:

    :enquiry_type
    :account_type_code
    :currency_code
    :enquiry_amount
    :client_reference

#### Class Methods:

    Veda::Request.access - Veda access details hash as defined by 'config/veda_config.yml'

#### Instance Methods:

    request.access - Access Hash
    request.product - Product Hash
    request.entity - Entity Hash
    request.enquiry - Enquiry Hash
    request.xml - XML body of request
    request.validate_xml - Validate the xml
    request.struct - Struct of body
    request.post - Post to Veda

### Response

    response = Veda::Response.create(xml: request.body, headers: request.headers, code: request.code, request_id: request.id)

#### Instance Methods:

    response.error - Response errors if any
    response.match - Struct of primary match
    response.struct - Struct of whole response
    response.xml - XML of response
    response.code - Response status code
    response.headers - Response headers
    response.validate_xml - Validate xml of response

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
