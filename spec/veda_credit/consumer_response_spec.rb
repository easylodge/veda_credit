require 'spec_helper'

describe VedaCredit::ConsumerResponse do
  it { should belong_to(:consumer_request).dependent(:destroy) } 
  it { should validate_presence_of(:consumer_request_id) }
  it { should validate_presence_of(:xml) }

  describe "with valid response xml" do
    before(:all) do
      @xml = File.read('spec/veda_credit/valid_consumer_response.xml')
      @headers = {"date"=>["Tue, 21 Oct 2014 13:16:48 GMT"], "server"=>["Apache-Coyote/1.1"], "http"=>[""], "content-type"=>["text/xml"], "content-length"=>["4888"], "connection"=>["close"]}
      @code = 200
      @success = true
      @request_id = 1
      @response = VedaCredit::ConsumerResponse.new(xml: @xml, headers: @headers, code: @code, success: @success, consumer_request_id: @request_id)
      @response.save
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

    describe ".as_hash" do
      it "returns whole response as hash" do
        expect(@response.as_hash.class).to eq(Hash)
      end
      it "accesses nested attributes" do
        expect(@response.as_hash["BCAmessage"]["type"]).to eq('RESPONSE')
      end
    end
  
    describe ".number_of_paid_defaults" do
      it "returns a integer" do
        expect(@response.number_of_paid_defaults.class).to eq(Fixnum)
      end
    end

    describe ".number_of_unpaid_defaults" do
      it "returns a integer" do
        expect(@response.number_of_unpaid_defaults.class).to eq(Fixnum)
      end
    end

    describe ".age_of_latest_default_in_months" do
      it "returns a integer if default" do
        @response.stub(:defaults).and_return([{"section"=>"Default", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}])
        expect(@response.age_of_latest_default_in_months.class).to eq(Fixnum)
      end
      it "returns a string if no default" do
        expect(@response.age_of_latest_default_in_months.class).to eq(String)
      end
    end

    describe ".number_of_enquiries_in_last_3_months" do
      it "returns a integer" do
        expect(@response.number_of_enquiries_in_last_3_months.class).to eq(Fixnum)
      end
    end

    describe ".number_of_enquiries_in_last_24_months" do
      it "returns a integer" do
        expect(@response.number_of_enquiries_in_last_24_months.class).to eq(Fixnum)
      end
    end

    describe ".age_of_latest_discharged_bankruptcy_in_months" do
      it "returns a integer if discharded bankruptcy" do
        @response.stub(:bankruptcies).and_return([{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2012-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"}])
        expect(@response.age_of_latest_discharged_bankruptcy_in_months.class).to eq(Fixnum)
      end
      it "returns a string if no discharded bankruptcy" do
        expect(@response.age_of_latest_discharged_bankruptcy_in_months.class).to eq(String)
      end
    end

    describe ".bankrupt?" do
      it "returns boolean" do
        expect(!!@response.bankrupt? == @response.bankrupt?).to be true #hack to check if boolean
      end
    end

    describe ".non_credit_defaults", :focus do
      it "returns empty array if no default" do
        expect(@response.non_credit_defaults).to eq([])        
      end
      it "returns array of defaults if default" do
         @response.stub(:defaults).and_return(
            [{"section"=>"Default", "account_type" => "Utilities", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"},
            {"section"=>"Default", "account_type" => "Telecommunication Service", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"},
            {"section"=>"Default", "account_type" => "Loan Contract", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}]
            )
        expect(@response.non_credit_defaults.count).to eq(2)
        expect(@response.non_credit_defaults.class).to eq(Array)        
      end
    end

    describe ".earliest_bankruptcy_date", :focus do
      it "returns a date if bankruptcy" do
        @response.stub(:bankruptcies).and_return(
          [{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2015-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"},
          {"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2012-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"}]
          )
        expect(@response.earliest_bankruptcy_date.class).to eq(Date)
        expect(@response.earliest_bankruptcy_date).to eq("2012-01-04".to_date)      
      end
      it "returns nil if no bankruptcy" do
        expect(@response.earliest_bankruptcy_date).to eq(nil)  
      end
    end

    describe ".latest_discharged_bankruptcy_date", :focus do
      it "returns a date if discharded bankruptcy" do
        @response.stub(:bankruptcies).and_return([{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2012-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"}])
        expect(@response.latest_discharged_bankruptcy_date.class).to eq(Date)
        expect(@response.latest_discharged_bankruptcy_date).to eq("2015-01-05".to_date)
      end
      it "returns nil if no discharded bankruptcy" do
        expect(@response.latest_discharged_bankruptcy_date).to eq(nil)
      end
    end

    describe ".subsequent_defaults", :focus do
      it "returns nil for no subsquent default" do
        expect(@response.subsequent_defaults).to eq(nil)        
      end
      it "returns date if subsequent default" do
        @response.stub(:bankruptcies).and_return([{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2012-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"}])
        @response.stub(:defaults).and_return(
            [{"section"=>"Default", "account_type" => "Utilities", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"},
            {"section"=>"Default", "account_type" => "Telecommunication Service", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2011-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"},
            {"section"=>"Default", "account_type" => "Loan Contract", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2015-02-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}]
            )
        expect(@response.subsequent_defaults).to eq("2015-02-05".to_date)
        expect(@response.subsequent_defaults.class).to eq(Date)         
      end
    end

    describe ".subsequent_part_ix_or_part_x_bankruptcies", :focus do
      it "returns false no subsquent part ix or x bankruptcies" do
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies).to eq(nil)        
      end
      it "returns date if subsequent part ix or x bankruptcies" do
         @response.stub(:bankruptcies).and_return(
          [{"section"=>"Bankruptcy", "account_type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2010-01-04", "role"=>"principal", "discharge_date"=>"2010-01-05", "discharge_status"=>"discharged"},
          {"section"=>"Bankruptcy", "account_type"=>"Personal Insolvency Agreement (Part 10 Deed)", "date"=>"2012-01-04", "role"=>"principal"}]
          )
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies).to eq("2012-01-04".to_date)
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies.class).to eq(Date)        
      end
    end
  end
  
end
