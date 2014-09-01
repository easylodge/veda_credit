require 'spec_helper'

describe VedaCredit::Response do
  it { should belong_to(:request).dependent(:destroy) } 
  it { should validate_presence_of(:request_id) }
  it { should validate_presence_of(:xml) }
  it { should validate_presence_of(:headers) }
  it { should validate_presence_of(:code) }
  it { should validate_presence_of(:success) }

  describe "with dev_config" do
    before(:all) do
  		@config = YAML.load_file('dev_config.yml')
      @access_hash = 
        {
          :url => @config["url"],
          :access_code => @config["access_code"],
          :password => @config["password"],
          :subscriber_id => @config["subscriber_id"],
          :security_code => @config["security_code"],
          :request_mode => @config["request_mode"]
          }
    
      @service_hash = 
        {
          :service_code => "VDA001",
          :service_code_version => 'V00',
          :request_version => '1.0'
          
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
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }
       @request = VedaCredit::Request.new(application_id: 1, access: @access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash)      
    end
     	
    describe "with valid request post" do
      
      before(:all) do 
        @post = @request.post
        @response = VedaCredit::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
      end
        
      
      
      describe '.headers' do
				it "returns response headers" do
          expect(@response.headers.class).to eq(HTTParty::Response::Headers)
        end
			end

      describe ".code" do
        it "returns response code" do
          expect(@response.code).to eq(200)
        end
      end

			describe '.xml' do
				it "returns xml string" do
          expect(@response.xml).to include('<?xml version="1.0"?>')
				end
			end

      describe '.validate_xml' do
        it "returns no errors" do
          expect(@response.validate_xml).to eq([])
        end
      end

      describe ".to_hash" do
        it "returns whole response as hash" do
          expect(@response.to_hash.class).to eq(Hash)
        end
        it "accesses nested attributes" do
          expect(@response.to_hash["BCAmessage"]["type"]).to eq('RESPONSE')
        end
      end

      describe '.success?' do
        it "returns true" do
          expect(@response.success?).to eq(true)
        end
      end       
		
      
    end
  
  
  describe "with post with invalid access details" do
    before do 
      access_hash = 
          {
              :url => @config["url"],
              :access_code => 'xxxxxx',
              :password => 'xxxxxx',
              :subscriber_id => 'xxxxxx',
              :security_code => 'xx',
              :request_mode => 'test'
              }
      @request = VedaCredit::Request.new(application_id: 1, access: access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash) 
      @post = @request.post
      @response = VedaCredit::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
    end
        
    it "has error response" do
      expect(@response.error).to eq("The Request Manager was unable to authenticate the VedaXML access code and password supplied. Check values of: /BCAmessage/BCAaccess/BCAaccess-code and /BCAmessage/BCAaccess/BCAaccess-pwd")
    end  
  end

  describe "with post with invalid product details" do
         
    before do 
      service_hash = 
              {
                :service_code => "xxxxx",
                :service_code_version => 'xx',
                :request_version => '1.0',
                
              }
      @request = VedaCredit::Request.new(application_id: 1, access: @access_hash, service: service_hash, entity: @entity_hash, enquiry: @enquiry_hash) 
      @post = @request.post
      @response = VedaCredit::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
    end
    
    it "has error response" do
      expect(@response.error).to eq("The BCAservice-code-version supplied was not valid. Check value of: /BCAmessage/BCAservice/BCAservice-code-version")
    end  
  end

  describe "with post with invalid entity details" do
     before do   

      entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :current_address => {
                  :street_name => "Arthur",
                  :suburb => "North Sydney",
                  :state => ""
                },
                :gender_type => 'male'
              }
      @request = VedaCredit::Request.new(application_id: 1, access: @access_hash, service: @service_hash, entity: entity_hash, enquiry: @enquiry_hash) 
      @post = @request.post
      @response = VedaCredit::Response.new(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
    end
        
    it "has error response" do
      expect(@response.error).to eq("Validation error: Address Details, STATE MUST BE ENTERED")
    end  
  end
  end
end
