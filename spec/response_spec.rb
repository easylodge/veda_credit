require 'spec_helper'

describe Veda do
	describe Veda::Response do
    it { should belong_to(:request).dependent(:destroy) } 
    it { should validate_presence_of(:request_id) }
    it { should validate_presence_of(:xml) }

    describe "with valid request post" do
  		access_hash = 
  				{
            :url => ACCESS_URL,
            :access_code => ACCESS_CODE,
            :password => ACCESS_PASSWORD,
            :subscriber_id => ACCESS_SUBSCRIBER,
            :security_code => ACCESS_SECURITY,
            :request_mode => ACCESS_MODE
  				    }

  		product_hash = 
  						{
  							:service_code => "BCA001",
  							:service_code_version => 'V00',
  							:request_version => '1.0',
  							:product_name => "consumer-enquiry",
  							:summary => "yes"
  						}

  		entity_hash = 
  						{
  							:family_name => 'Verry',
  							:first_given_name => 'Dore',
  							:employer => 'Veda',
  							:address_type => 'residential-current',
  							:street_name => "Arthur",
  							:suburb => "North Sydney",
  							:state => "NSW",
  							:gender_type => 'male'
  						}

  		enquiry_hash =
  						{
  							:enquiry_type => 'credit-application',
  							:account_type_code => 'LC',
  							:currency_code => 'AUD',
  							:enquiry_amount => '5000',
  							:client_reference => '123456789'
  						} 
     	let(:request) { Veda::Request.new(access: access_hash, product: product_hash, entity: entity_hash, enquiry: enquiry_hash) }
      before do 
        @post = request.post
      end
        
      let(:response) { Veda::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, request_id: request.id)}
      
      describe '.headers' do
				it "returns response headers" do
          expect(response.headers.class).to eq(HTTParty::Response::Headers)
        end
			end

      describe ".code" do
        it "returns response code" do
          expect(response.code).to eq(200)
        end
      end

			describe '.xml' do
				it "returns xml string" do
          expect(response.xml).to include('<?xml version="1.0"?>')
				end
			end

      describe '.validate_xml' do
        it "returns no errors" do
          expect(response.validate_xml).to eq([])
        end
      end

      describe ".struct" do
        it "returns whole response as open struct" do
          expect(response.struct.class).to eq(RecursiveOpenStruct)
        end
        it "accesses nested attributes" do
          expect(response.struct.type).to eq('RESPONSE')
        end
      end 
		
      describe ".match" do
        it "returns the primary match as open struct" do
           expect(response.match.class).to eq(RecursiveOpenStruct)
        end

        it "accesses nested attributes"  do
          expect(response.match.individual.individual_name.first_given_name).to eq("DORE")
        end
      end
    end
  end
  
  describe "with post with invalid access details" do
    access_hash = 
          {
              :url => ACCESS_URL,
              :access_code => 'xxxxxx',
              :password => 'xxxxxx',
              :subscriber_id => 'xxxxxx',
              :security_code => 'xx',
              :request_mode => 'test'
              }

      product_hash = 
              {
                :service_code => "BCA001",
                :service_code_version => 'V00',
                :request_version => '1.0',
                :product_name => "consumer-enquiry",
                :summary => "yes"
              }

      entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :address_type => 'residential-current',
                :street_name => "Arthur",
                :suburb => "North Sydney",
                :state => "NSW",
                :gender_type => 'male'
              }

      enquiry_hash =
              {
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              } 
      let(:request) { Veda::Request.new(access: access_hash, product: product_hash, entity: entity_hash, enquiry: enquiry_hash) }
      before do 
        @post = request.post
      end
        
      let(:response) { Veda::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, request_id: request.id)}

      it "has error response" do
        expect(response.error).to eq({"type"=>"AUTHENTICATION", "BCAerror_code"=>"ERR1005", "BCAerror_description"=>"The Request Manager was unable to authenticate the VedaXML access code and password supplied. Check values of: /BCAmessage/BCAaccess/BCAaccess-code and /BCAmessage/BCAaccess/BCAaccess-pwd"})
      end  
  end

  describe "with post with invalid product details" do
    access_hash = 
          {
              :url => ACCESS_URL,
              :access_code => ACCESS_CODE,
              :password => ACCESS_PASSWORD,
              :subscriber_id => ACCESS_SUBSCRIBER,
              :security_code => ACCESS_SECURITY,
              :request_mode => ACCESS_MODE
              }

      product_hash = 
              {
                :service_code => "xxxxx",
                :service_code_version => 'xx',
                :request_version => '1.0',
                :product_name => "consumer-enquiry",
                :summary => "yes"
              }

      entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :address_type => 'residential-current',
                :street_name => "Arthur",
                :suburb => "North Sydney",
                :state => "NSW",
                :gender_type => 'male'
              }

      enquiry_hash =
              {
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              } 
      let(:request) { Veda::Request.new(access: access_hash, product: product_hash, entity: entity_hash, enquiry: enquiry_hash) }
      before do 
        @post = request.post
      end
        
      let(:response) { Veda::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, request_id: request.id)}

      it "has error response" do
        expect(response.error).to eq({"type"=>"VALIDATION", "BCAerror_code"=>"ERR1015.2", "BCAerror_description"=>"The BCAservice-code-version supplied was not valid. Check value of: /BCAmessage/BCAservice/BCAservice-code-version"})
      end  
  end

  describe "with post with invalid entity details" do
    access_hash = 
          {
              :url => ACCESS_URL,
              :access_code => ACCESS_CODE,
              :password => ACCESS_PASSWORD,
              :subscriber_id => ACCESS_SUBSCRIBER,
              :security_code => ACCESS_SECURITY,
              :request_mode => ACCESS_MODE
              }

      product_hash = 
              {
                :service_code => "BCA001",
                :service_code_version => 'V00',
                :request_version => '1.0',
                :product_name => "consumer-enquiry",
                :summary => "yes"
              }

      entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :address_type => 'residential-current',
                :street_name => "Arthur",
                :suburb => "North Sydney",
                :state => "",
                :gender_type => 'male'
              }

      enquiry_hash =
              {
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              } 
      let(:request) { Veda::Request.new(access: access_hash, product: product_hash, entity: entity_hash, enquiry: enquiry_hash) }
      before do 
        @post = request.post
      end
        
      let(:response) { Veda::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, request_id: request.id)}

      it "has error response" do
        expect(response.error).to eq({"error_type"=>"validation", "input_container"=>"Address Details", "error_description"=>"STATE MUST BE ENTERED"})
      end  
  end

end
