require 'spec_helper'

describe EquifaxCredit::CommercialRequest do
  it { should have_one(:commercial_response).dependent(:destroy) }
  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:entity) }
  it { should validate_presence_of(:enquiry) }

  describe "with valid access, service and entity hash" do

    before(:all) do 
      @access_hash = 
        {
          :url => "url",
          :username => "username",
          :password => "password",
        }
      @service_hash = 
        {
          :service_code => "XML2"
        }
      @entity_hash = 
        { 
          :acn => "000105233",
          :bureau_reference => "BFN 001" 
        }   
      @enquiry_hash =
        {
          :role => 'principal',
          :enquiry_id => '1223334',
          :enquiry_type => 'credit-review',
          :request_type => "REPORT",
          :account_type_code => 'HC',
          :account_type => 'HIREPURCHASE',
          :currency_code => 'AUD',
          :enquiry_amount => '5000',
          :client_reference => '123456789',
          :current_and_history => "current",
          :reason_for_enquiry => "Application",
          :current_and_history => "current",
          :scoring_required => "no",
          :enrichment_required => "no",
          :ppsr_required => "no",
          :credit_type => "COMMERCIAL",
        }
      @request = EquifaxCredit::CommercialRequest.new(ref_id: 1, access: @access_hash, service: @service_hash, entity: @entity_hash, enquiry: @enquiry_hash)
      @request.save
    end

    describe ".access" do
      it "returns access details hash used to build request" do
        expect(@request.access).to eq({
                                  :url => "url",
                                  :username => "username",
                                  :password => "password",
                                  })
      end
    end

    describe ".service" do
      it "returns product details hash used to build request" do
        expect(@request.service).to eq({
                                  :service_code => "XML2"
                                })
      end
    end

    describe ".entity" do
      it "returns entity details hash used to build request" do
        expect(@request.entity).to eq(
          { 
          :acn => "000105233",
          :bureau_reference => "BFN 001" 
        } )
      end
    end

    describe ".enquiry" do
      it "returns enquiry details hash used to build request" do
        expect(@request.enquiry).to eq({
          :role => 'principal',
          :enquiry_id => '1223334',
          :enquiry_type => 'credit-review',
          :request_type => "REPORT",
          :account_type_code => 'HC',
          :account_type => 'HIREPURCHASE',
          :currency_code => 'AUD',
          :enquiry_amount => '5000',
          :client_reference => '123456789',
          :current_and_history => "current",
          :reason_for_enquiry => "Application",
          :current_and_history => "current",
          :scoring_required => "no",
          :enrichment_required => "no",
          :ppsr_required => "no",
          :credit_type => "COMMERCIAL",
        })
      end
    end

    describe ".xml" do
      it "returns a soap request" do
        expect(@request.xml).to include("<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:com=\"http://vedaxml.com/vxml2/company-enquiry-v3-2.xsd\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">")
      end

      it "includes username" do
        expect(@request.xml).to include("<wsse:Username>username</wsse:Username>")
      end

      it "includes password" do
        expect(@request.xml).to include("<wsse:Password>password</wsse:Password>")
      end

      it "includes acn" do
        expect(@request.xml).to include("<com:australian-company-number>000105233</com:australian-company-number>")
      end

      it "includes enquiry type" do
        expect(@request.xml).to include("<com:enquiry type=\"credit-review\">")
      end

      it "includes account type code" do
        expect(@request.xml).to include("com:account-type code=\"HC\"")
      end

      # it "is nil" do 
      #   expect(@request.xml).to eq(nil)
      # end

      
    end

  end
end