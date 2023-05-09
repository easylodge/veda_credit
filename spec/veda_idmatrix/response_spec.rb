require 'spec_helper'

describe VedaIdmatrix::Response do
  it { should belong_to(:request).dependent(:destroy) }

  describe ".initialize" do
    it "converts :header to a hash" do
      not_a_hash = OpenStruct.new
      expect(not_a_hash).to receive(:to_h)
      VedaIdmatrix::Response.new(headers: not_a_hash)
    end
  end

  describe "request/response cycle" do
    before(:all) do
      @config = YAML.load_file('dev_config.yml')
      @access_hash =
        {
          :url => @config["url"],
          :access_code => @config["access_code"],
          :password => @config["password"]
        }

      @entity_hash = {
        :family_name => "DVSTest",
        :first_given_name => "Arnold",
        :date_of_birth => "1988-09-01",
        :gender => "male",
        :current_address => {
          :street_number => "190",
          :street_name => "Neerim",
          :street_type => "Rd",
          :suburb => "CARNEGIE",
          :state => "VIC",
          :postcode => "3163",
          :unformatted_address => "190 Neerim Rd CARNEGIE VIC 3163"
        },
        # :home_phone_number => "0312345678",
        # :mobile_phone_number => "0487654321",
        # :work_phone_number => "040012312",
        # :phone_authentication_number => "0487654321",
        # :send_pin_method => "sms",
        # :email_address => "harry.potter@example.com",
        # :alternative_email_address => "hpotter@example.com",
        :drivers_licence_state_code => "QLD",
        :drivers_licence_number => "112813476",
        :drivers_licence_card_number => "123454321",
        # :drivers_licence_date_of_expiry => "2000-01-01",
        # :drivers_licence_card_number => "1234567890",
        :passport_country_code => "AUS",
        :passport_number => "N1000091",
        # :name_at_citizenship => {
        #   :family_name => "Potter",
        #   :first_given_name => "Harry",
        #   :other_given_name => "James"
        # },
        # :place_of_birth => "Little Whinging",
        # :country_of_birth => "AUS",
        :medicare_card_number => "2951636282",
        :medicare_reference_number => "1",
        :medicare_card_color => "G",
        :medicare_card_expiry => "2000-01"
        # :birth_cert_reg_number => "12345679890",
        # :birth_cert_reg_state =>"NSW",
        # :birth_cert_reg_date => "1980-08-02",
        # :birth_cert_reg_name => {
        #   :family_name => "Potter",
        #   :first_given_name => "Harry",
        #   :other_given_name => "James"
        # },
        # :marriage_cert_reg_number => "1234567890",
        # :marriage_cert_reg_state => "NSW",
        # :marriage_cert_reg_year => "2000",
        # :marriage_date => "2000-02-02",
        # :brides_name => {
        #   :family_name => "Wesley",
        #   :first_given_name => "Ginny"
        # },
        # :grooms_name => {
        #   :family_name => "Potter",
        #   :first_given_name => "Harry",
        #   :other_given_name => "James"
        # },
        # :device_intelligence_org_id => "org-abc",
        # :device_intelligence_session_id => "X123"
      }

      @enquiry_hash = {
        :client_reference => "123456",
        :reason_for_enquiry => "Test"
      }
    end

    describe "created by request.post with valid access details" do
      before(:all) do
        @request = VedaIdmatrix::Request.new(ref_id: 1, access: @access_hash, entity: @entity_hash, enquiry: @enquiry_hash)
        @post = @request.post
        @response = VedaIdmatrix::Response.create(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
      end

      describe "is valid" do
        it "returns true" do
          expect(@response.valid?).to be(true)
        end
      end

      describe ".code" do
        it "returns status code" do
          expect(@response.code).to be(200)
        end
      end

      describe ".headers" do
        it "returns headers" do
          expect(@response.headers).to include("content-type")
        end
      end

      describe ".success?" do
        it "returns boolean of post action" do
          expect(@response.success?).to be(true)
        end
      end

      describe ".request_id" do
        it "returns request_id" do
          expect(@response.request_id).to eq(@request.id)
        end
      end

      describe ".xml" do
        it "returns xml response body" do
          expect(@response.xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
        end
      end

      describe ".to_hash" do
        it "returns hash of response body" do
          expect(@response.to_hash.class).to be(Hash)
        end
      end

      describe ".error" do
        it "returns message" do
          expect(@response.error).to eq("No error")
        end
      end
    end

    describe "created by request.post with invalid access details" do
      before(:all) do
        @request = VedaIdmatrix::Request.new(
          access: {
            url: @config["url"],
            user_code: "xxxxx",
            password: "xxxxx",
            },
          entity: @entity_hash,
          enquiry: @enquiry_hash)
        @post = @request.post
        @response = VedaIdmatrix::Response.create(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
      end

      describe "is valid" do

        it "returns true" do
          expect(@response.valid?).to be(true)
        end

        it "can save" do
          expect(@response.save!).to eq(true)
        end
      end

      describe ".code" do
        it "returns server status code" do
          expect(@response.code).to eq(500)
        end
      end

      describe ".headers" do
        it "returns headers" do
          expect(@response.headers).to include("content-type")
        end
      end

      describe ".success?" do
        it "returns boolean of post action" do
          expect(@response.success?).to be(false)
        end
      end

      describe ".request_id" do
        it "returns request_id" do
          expect(@response.request_id).to eq(@request.id)
        end
      end

      describe ".xml" do
        it "returns xml response body" do
          expect(@response.xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
        end
      end

      describe ".error" do
        it "returns message" do
          expect(@response.error).to include("Authentication Required")
        end
      end
    end

    describe "created by request.post with incorrect password" do

      before(:all) do
        @request = VedaIdmatrix::Request.new(
          access: {
            url: @config["url"],
            access_code: @config["access_code"],
            password: "xxxxx",
            },
          entity: @entity_hash,
          enquiry: @enquiry_hash)
        @post = @request.post
        @response = VedaIdmatrix::Response.create(xml: @post.body, headers: @post.headers, code: @post.code, success: @post.success?, request_id: @request.id)
      end

      it "is valid" do
        expect(@response.valid?).to be(true)
      end

      describe ".code" do
        it "returns server status code" do
          expect(@response.code).to eq(500)
        end
      end

      describe ".headers" do
        it "returns headers" do
          expect(@response.headers).to include("content-type")
        end
      end

      describe ".success?" do
        it "returns boolean of post action" do
          expect(@response.success?).to be(false)
        end
      end


      describe ".success" do
        it "returns boolean of post action" do
          expect(@response.success).to be(false)
        end
      end

      describe ".request_id" do
        it "returns request_id" do
          expect(@response.request_id).to eq(@request.id)
        end
      end

      describe ".xml" do
        it "returns xml response body" do
          expect(@response.xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
        end
      end

     describe ".error" do
        it "returns message" do
          expect(@response.error).to include("Authentication Failed")
        end
      end
    end
  end
end
