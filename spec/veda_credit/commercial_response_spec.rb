require 'spec_helper'

describe VedaCredit::CommercialResponse do
  it { should belong_to(:commercial_request).dependent(:destroy) } 
  it { should validate_presence_of(:commercial_request_id) }
  it { should validate_presence_of(:xml) }

  it ".to_s" do
    expect(subject.to_s).to eq("Veda Credit Commercial Response")
  end

  context "with valid xml" do
    before(:all) do
      @xml = File.read('spec/veda_credit/CE_Resp.xml')
      @headers = {"date"=>["Tue, 21 Oct 2014 13:16:48 GMT"], "server"=>["Apache-Coyote/1.1"], "http"=>[""], "content-type"=>["text/xml"], "content-length"=>["4888"], "connection"=>["close"]}
      @request_id = 1
      @response = VedaCredit::CommercialResponse.new(xml: @xml, commercial_request_id: @request_id)
      @response.save
    end
      
    it ".xml returns xml string" do
      expect(@response.xml).to include('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vh="http://vedaxml.com/soap/header/v-header-v1-9.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">')
    end

    context ".get_hash" do
      ["credit-enquiry-list","organisation-report-header","summary-data","organisation-legal","company-identity","directors-list","secretary-list"].each do |search_term|
        it "returns a hash for #{search_term}" do
          expect(@response.send(:get_hash, search_term)).to be_a(Hash)
          expect(@response.send(:get_hash, search_term)).not_to be_blank
        end
      end
    end
    
    context ".company_enquiry_header" do
      it "returns a hash" do
        expect(@response.company_enquiry_header).to be_a(Hash)
      end
      it "contains required fields" do
        hsh = @response.company_enquiry_header
        ["request_id", "member_code", "branch_code", "channel_code", "charge_back_code",
         "with_links", "trade_payments_required", "organisation_name", "asic_extract_date", "report_created"].each do |key|
          expect(hsh.has_key?(key)).to eq(true)
        end
      end
    end

    context ".company_identity" do
      it "returns a hash" do
        expect(@response.company_identity).to be_a(Hash)
      end
      it "contains required addresses" do
        hsh = @response.company_identity
        expect(hsh.has_key?("registered_office")).to eq(true)
        expect(hsh["registered_office"].has_key?("address")).to eq(true)
        expect(hsh.has_key?("principal_place_of_business")).to eq(true)
        expect(hsh["principal_place_of_business"].has_key?("address")).to eq(true)
      end
    end

    context ".summary_data" do
      it "returns a hash" do
        expect(@response.summary_data).to be_a(Hash)
      end
      it "keys are underscored" do
        hsh = @response.summary_data
        hsh.keys.each do |key|
          expect(key).to eq(key.underscore)
        end
      end
    end

    context ".credit_enquiries" do
      it "returns a array" do
        expect(@response.credit_enquiries).to be_a(Array)
      end
      it "contains required fields" do
        arr = @response.credit_enquiries
        ["enquiry_date","credit_enquirer","reference_number","amount","account_type_code","account_type","role_in_enquiry"].each do |key|
          expect(arr.first.has_key?(key)).to eq(true)
        end
      end
    end

    context ".file_messages" do
      it "returns a array" do
        expect(@response.file_messages).to be_a(Array)
      end
      it "contains required fields" do
        arr = @response.file_messages
        expect(arr).not_to be_blank
      end
    end

    context ".directors" do
      it "returns a array" do
        expect(@response.directors).to be_a(Array)
      end
      it "contains required fields" do
        arr = @response.directors
        ["address","director_name","place_of_birth"].each do |key|
          expect(arr.first.has_key?(key)).to eq(true)
        end
      end
    end

    context ".secretaries" do
      it "returns a array" do
        expect(@response.secretaries).to be_a(Array)
      end
      it "contains required fields" do
        arr = @response.secretaries
        ["address","secretary_name","place_of_birth"].each do |key|
          expect(arr.first.has_key?(key)).to eq(true)
        end
      end
    end
  end

  context ".age_of_file" do
    it "returns age of file from creation date"
  end

  context ".error" do
    it "xml - returns error message" do
      @xml = File.read('spec/veda_credit/commercial_error_response.xml')
      @response = VedaCredit::CommercialResponse.new(xml: @xml, commercial_request_id: 1)
      @response.save
      
      expect(@response.error).to eq("Error: 030 - ASIC Org Extract Gateway Unavailable")
    end
    it "html - returns error message" do
      @xml = File.read('spec/veda_credit/commercial_html_error.html')
      @response = VedaCredit::CommercialResponse.new(xml: @xml, commercial_request_id: 1)
      @response.save
      
      expect(@response.error).to eq("Bad Request The request sent by the client was syntactically incorrect.")
    end
  end
end