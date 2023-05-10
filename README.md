# Equifax

Ruby gem to make requests to Equifax service. Website: [https://www.equifax.com.au](https://www.equifax.com.au/)

## Installation

Add this line to your application's Gemfile:

    gem 'equifax'

And then execute:

    $ bundle

Then run install generator:

	rails g equifax:install

Then run migrations:

	rake db:migrate


## Usage

### Request


    request = EquifaxCredit::Request.create(application_id: 123456, access: access_hash, service: service_hash, entity: entity_hash, enquiry: enquiry_hash)

Attributes for access_hash:

    {
      :url => config["url"],
      :access_code => config["access_code"],
      :password => config["password"],
      :subscriber_id => config["subscriber_id"],
      :security_code => config["security_code"],
      :request_mode => config["request_mode"],
      :timeout => config["timeout"]
    }

Attributes for service_hash:

    {
      :service_code => "VDA001",
      :service_code_version => 'V00',
      :request_version => '1.0',
    }

Attributes for entity_hash:

    {
      :family_name => "Potter",
      :first_given_name => "James",
      :other_given_name => "Harry",
      :date_of_birth => "1980-07-31",
      :gender => "male",
      :current_address => {
        :property => "Potter Manor",
        :unit_number => "3",
        :street_number => "4",
        :street_name => "Privet",
        :street_type => "Drive",
        :suburb => "Little Whinging",
        :state => "NSW",
        :postcode => "2999",
        :country_code => "AU",
      },
      :previous_address => {
        :property => "Equifax House",
        :unit_number => "15",
        :street_number => "100",
        :street_name => "Arthur",
        :street_type => "Street",
        :suburb => "North Sydney",
        :state => "NSW",
        :postcode => "2060",
        :country_code => "AU",
      },
      :home_phone_number => "0312345678",
      :mobile_phone_number => "0487654321",
      :work_phone_number => "040012312",
      :email_address => "harry.potter@example.com",
      :alternative_email_address => "hpotter@example.com",
      :drivers_licence_state_code => "NSW",
      :drivers_licence_number => "1234567890"
    }

    if unformatted address is present as below it will be used instead of the formatted address above
    :current_address => {:unformatted_address => "Potter Manor 3/4 Privet Drive Little Whinging NSW 2999"}

Attributes for enquiry_hash:

    {
      :product_name=>"equifaxscore-financial-consumer-1.1",
      :summary=>"yes",
      :role=>"principal",
      :enquiry_type => 'credit-application',
      :account_type_code => 'LC',
      :currency_code => 'AUD',
      :enquiry_amount => '5000',
    }

#### Instance Methods:

    request.application_id - Your reference number
    request.access - Access Hash
    request.service - Service Hash
    request.entity - Entity Hash
    request.enquiry - Enquiry Hash
    request.xml - XML body of request
    request.schema - XSD that xml is validated against
    request.validate_xml - Validate the xml
    request.post - Post to Equifax

### Response

    post = request.post
    response = EquifaxCredit::Response.create(xml: post.body, headers: post.headers, code: post.code, success: post.success?, request_id: request.id)

#### Instance Methods:

    response.to_hash - Hash of whole response
    response.xml - XML of response
    response.code - Response status code
    response.headers - Response headers
    response.success? - Returns true or false (based on Httparty response)
    response.error - Response errors if any
    response.primary_match - Hash of primary match result
    response.summary_data - Hash of summary data result
    response.score_card - Hash of score card result

## Contributing

1. Fork it ( http://github.com/<my-github-username>/equifax/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. See dev.rb file in root
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
