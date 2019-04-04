require 'spec_helper'

describe EquifaxCredit::ConsumerRequest do
  it { should have_one(:consumer_response).dependent(:destroy) }
  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:entity) }
  it { should validate_presence_of(:enquiry) }

  describe "with valid access, service and entity hash" do

    before(:all) do 
      @access_hash = 
        {
          :url => "url",
          :access_code => "access_code",
          :password => "password",
          :subscriber_id => "subscriber_id",
          :security_code => "security_code",
          :request_mode => "request_mode"
        }
      @service_hash = 
        {
          :service_code => "VDA001",
          :service_code_version => 'V00',
          :request_version => '1.0',
        }
      @entity_hash = 
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
            :unformatted_address => "Potter Manor 3/4 Privet Drive Little Whinging NSW 2999"
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
            :unformatted_address => "Equifax House 15/100 Arthur Street North Sydney NSW 2060"
          },
          :home_phone_number => "0312345678",
          :mobile_phone_number => "0487654321",
          :work_phone_number => "040012312",
          :email_address => "harry.potter@example.com",
          :alternative_email_address => "hpotter@example.com",
          :drivers_licence_state_code => "NSW",
          :drivers_licence_number => "1234567890",
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
      @request = EquifaxCredit::ConsumerRequest.new(ref_id: 1, access: @access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash)
      @request.save
    end

    describe ".access" do
      it "returns access details hash used to build request" do
        expect(@request.access).to eq({
                                  :url => @access_hash[:url],
                                  :access_code => @access_hash[:access_code],
                                  :password => @access_hash[:password],
                                  :subscriber_id => @access_hash[:subscriber_id],
                                  :security_code => @access_hash[:security_code],
                                  :request_mode => @access_hash[:request_mode]
                                  })
      end
    end

    describe ".service" do
      it "returns product details hash used to build request" do
        expect(@request.service).to eq({
                                  :service_code => "VDA001",
                                  :service_code_version => 'V00',
                                  :request_version => '1.0',
                                })
      end
    end

    describe ".entity" do
      it "returns entity details hash used to build request" do
        expect(@request.entity).to eq(
          { :family_name=>"Potter", 
            :first_given_name=>"James", 
            :other_given_name=>"Harry", 
            :date_of_birth=>"1980-07-31", 
            :gender=>"male", 
            :current_address=>{
              :property=>"Potter Manor", 
              :unit_number=>"3", 
              :street_number=>"4", 
              :street_name=>"Privet", 
              :street_type=>"Drive", 
              :suburb=>"Little Whinging", 
              :state=>"NSW", 
              :postcode=>"2999",
              :country_code => "AU", 
              :unformatted_address=>"Potter Manor 3/4 Privet Drive Little Whinging NSW 2999"
              }, 
            :previous_address=>{
              :property=>"Equifax House",
              :unit_number=>"15", 
              :street_number=>"100", 
              :street_name=>"Arthur", 
              :street_type=>"Street", 
              :suburb=>"North Sydney", 
              :state=>"NSW", 
              :postcode=>"2060",
              :country_code => "AU", 
              :unformatted_address=>"Equifax House 15/100 Arthur Street North Sydney NSW 2060"
              }, 
            :home_phone_number=>"0312345678", 
            :mobile_phone_number=>"0487654321", 
            :work_phone_number=>"040012312", 
            :email_address=>"harry.potter@example.com", 
            :alternative_email_address=>"hpotter@example.com", 
            :drivers_licence_state_code=>"NSW", 
            :drivers_licence_number=>"1234567890"

          })
      end
    end

    describe ".enquiry" do
      it "returns enquiry details hash used to build request" do
        expect(@request.enquiry).to eq({
                                  :product_name=>"vedascore-financial-consumer-1.1", 
                                  :summary=>"yes",
                                  :role=>"principal",
                                  :enquiry_type => 'credit-application',
                                  :account_type_code => 'LC',
                                  :currency_code => 'AUD',
                                  :enquiry_amount => '5000',
                                  :client_reference => '123456789'
                                })
      end
    end

    describe ".xml" do
      it "returns a xml request" do
        expect(@request.xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      end

      it "includes access code" do
        expect(@request.xml).to include("<BCAaccess-code>access_code</BCAaccess-code>")
      end

      it "includes password" do
        expect(@request.xml).to include("<BCAaccess-pwd>password</BCAaccess-pwd>")
      end

      it "includes subscriber_id" do
        expect(@request.xml).to include("subscriber-identifier>subscriber_id</subscriber-identifier>")
      end

      it "includes security code" do
        expect(@request.xml).to include("<security>security_code</security>")
      end

      it "includes mode" do
        expect(@request.xml).to include(%Q{<request version="1.0" mode="request_mode">})
      end

      it "includes enquiry type" do
        expect(@request.xml).to include('<enquiry type="credit-application">')
      end

      it "includes account type" do
        expect(@request.xml).to include('<account-type code="LC"/>')
      end

      # it "is nil" do 
      #   expect(@request.xml).to eq(nil)
      # end

      
    end

    describe "with unformatted address" do
      it "has unformatted_address in the entity hash"do
        expect(@request.entity[:current_address][:unformatted_address]).to eq('Potter Manor 3/4 Privet Drive Little Whinging NSW 2999')
      end

        
      it "uses unformatted_address when present" do
        expect(@request.xml).to include('<unformatted-address type="residential-current">Potter Manor 3/4 Privet Drive Little Whinging NSW 2999</unformatted-address>')
      end
    end
  end
end




        

        

    		

     