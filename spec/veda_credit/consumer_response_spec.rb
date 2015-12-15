require 'spec_helper'

describe VedaCredit::ConsumerResponse do
  it { should belong_to(:consumer_request).dependent(:destroy) }
  it { should validate_presence_of(:consumer_request_id) }
  it { should validate_presence_of(:xml) }

  it {expect(subject.class).to respond_to(:nested_hash_value)}
  it {expect(subject).to respond_to(:consumer_plus_commercial?)}
  it {expect(subject).to respond_to(:commercial_plus_consumer?)}
  it {expect(subject).to respond_to(:commercial_service_version)}
  it {expect(subject).to respond_to(:service_version)}
  it {expect(subject).to respond_to(:error)}
  it {expect(subject).to respond_to(:success?)}
  it {expect(subject).to respond_to(:validate_xml)}
  it {expect(subject).to respond_to(:schema)}
  it {expect(subject).to respond_to(:to_s)}
  it {expect(subject).to respond_to(:enquiry_report)}
  it {expect(subject).to respond_to(:service_request_id)}
  it {expect(subject).to respond_to(:primary_match)}
  it {expect(subject).to respond_to(:score_data)}
  it {expect(subject).to respond_to(:summary_data)}

  it {expect(subject).to respond_to(:number_of_cross_references)}
  it {expect(subject).to respond_to(:number_of_bankruptcies)}
  it {expect(subject).to respond_to(:discharged_bankruptcies)}
  it {expect(subject).to respond_to(:number_of_discharged_bankruptcies)}
  it {expect(subject).to respond_to(:number_of_discharged_bankruptcies_last_12_months)}
  it {expect(subject).to respond_to(:number_of_part_x_bankruptcies)}
  it {expect(subject).to respond_to(:number_of_part_ix_bankruptcies)}
  it {expect(subject).to respond_to(:number_of_clearout)}
  it {expect(subject).to respond_to(:number_of_clearouts)}
  it {expect(subject).to respond_to(:paid_defaults)}
  it {expect(subject).to respond_to(:unpaid_defaults)}
  it {expect(subject).to respond_to(:non_credit_defaults)}
  it {expect(subject).to respond_to(:credit_clearouts)}

  [12, 24, 36, 48, 60, 72].each do |term|
    it {expect(subject).to respond_to("paid_defaults_#{term}".to_sym)}
    it {expect(subject).to respond_to("paid_defaults_#{term}_amount".to_sym)}
    it {expect(subject).to respond_to("unpaid_defaults_#{term}".to_sym)}
    it {expect(subject).to respond_to("unpaid_defaults_#{term}_amount".to_sym)}
    it {expect(subject).to respond_to("last_#{term}_months_paid_defaults_amount".to_sym)}
    it {expect(subject).to respond_to("last_#{term}_months_unpaid_defaults_amount".to_sym)}
    it {expect(subject).to respond_to("non_credit_clearouts_#{term}".to_sym)}
    it {expect(subject).to respond_to("non_credit_clearouts_#{term}_amount".to_sym)}
    it {expect(subject).to respond_to("credit_clearouts_#{term}".to_sym)}
    it {expect(subject).to respond_to("credit_clearouts_#{term}_amount".to_sym)}
  end

  it {expect(subject).to respond_to(:unpaid_defaults_total_amount)}
  it {expect(subject).to respond_to(:unpaid_defaults_total)}
  it {expect(subject).to respond_to(:paid_defaults_total_amount)}
  it {expect(subject).to respond_to(:paid_defaults_total)}
  it {expect(subject).to respond_to(:credit_clearouts_total)}
  it {expect(subject).to respond_to(:non_credit_clearouts_total)}

  it {expect(subject).to respond_to(:file_message)}
  it {expect(subject).to respond_to(:bureau_reference)}
  it {expect(subject).to respond_to(:individual)}
  it {expect(subject).to respond_to(:defaults)}
  it {expect(subject).to respond_to(:commercial_defaults)}
  it {expect(subject).to respond_to(:credit_enquiries)}
  it {expect(subject).to respond_to(:commercial_credit_enquiries)}
  it {expect(subject).to respond_to(:court_actions)}
  it {expect(subject).to respond_to(:directorships)}
  it {expect(subject).to respond_to(:proprietorships)}
  it {expect(subject).to respond_to(:bankruptcies)}
  it {expect(subject).to respond_to(:cross_references)}
  it {expect(subject).to respond_to(:employment_histories)}
  it {expect(subject).to respond_to(:number_of_paid_defaults)}
  it {expect(subject).to respond_to(:number_of_unpaid_defaults)}
  it {expect(subject).to respond_to(:paid_credit_provider_defaults)}
  it {expect(subject).to respond_to(:age_of_latest_default_in_months)}
  it {expect(subject).to respond_to(:age_of_latest_discharged_bankruptcy_in_months)}
  it {expect(subject).to respond_to(:number_of_enquiries_in_last_3_months)}
  it {expect(subject).to respond_to(:number_of_enquiries_in_last_24_months)}
  it {expect(subject).to respond_to(:bankrupt?)}
  it {expect(subject).to respond_to(:earliest_bankruptcy_date)}
  it {expect(subject).to respond_to(:latest_discharged_bankruptcy_date)}
  it {expect(subject).to respond_to(:latest_default_date)}
  it {expect(subject).to respond_to(:subsequent_defaults)}
  it {expect(subject).to respond_to(:latest_credit_default_date)}
  it {expect(subject).to respond_to(:subsequent_credit_defaults)}
  it {expect(subject).to respond_to(:latest_non_credit_default_date)}
  it {expect(subject).to respond_to(:subsequent_non_credit_defaults)}
  it {expect(subject).to respond_to(:subsequent_part_ix_or_part_x_bankruptcies)}
  it {expect(subject).to respond_to(:part_x_bankruptcies)}
  it {expect(subject).to respond_to(:part_ix_bankruptcies)}
  it {expect(subject).to respond_to(:external_administration)}

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
        @response.stub(:defaults).and_return([
          {"section"=>"Default", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}.with_indifferent_access
        ])
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

    describe ".non_credit_defaults" do
      it "returns empty array if no default" do
        expect(@response.non_credit_defaults).to eq([])
      end
      it "returns array of defaults if default" do
         @response.stub(:defaults).and_return(
            [
              {"section"=>"Default", "account_type" => "Utilities", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}.with_indifferent_access,
              {"section"=>"Default", "account_type" => "Telecommunication Service", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}.with_indifferent_access,
              {"section"=>"Default", "account_type" => "Loan Contract", "type"=>"Loan Contract,Settled,Clearout", "date"=>"2010-10-05", "creditor"=>"ACME GROUP LTD", "current_amount"=>"6910", "original_amount"=>"6910", "role"=>"principal", "reference"=>"12345"}.with_indifferent_access]
            )
        expect(@response.non_credit_defaults.count).to eq(2)
        expect(@response.non_credit_defaults.class).to eq(Array)
      end
    end

    describe ".earliest_bankruptcy_date" do
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

    describe ".latest_discharged_bankruptcy_date" do
      it "returns a date if discharded bankruptcy" do
        @response.stub(:bankruptcies).and_return([{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2012-01-04", "role"=>"principal", "discharge_date"=>"2015-01-05", "discharge_status"=>"discharged"}])
        expect(@response.latest_discharged_bankruptcy_date.class).to eq(Date)
        expect(@response.latest_discharged_bankruptcy_date).to eq("2015-01-05".to_date)
      end
      it "returns nil if no discharded bankruptcy" do
        expect(@response.latest_discharged_bankruptcy_date).to eq(nil)
      end
    end

    describe ".subsequent_defaults" do
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

    describe ".subsequent_part_ix_or_part_x_bankruptcies" do
      it "returns false no subsquent part ix or x bankruptcies" do
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies).to eq(nil)
      end
      it "returns date if subsequent part ix or x bankruptcies" do
         @response.stub(:bankruptcies).and_return(
          [{"section"=>"Bankruptcy", "type"=>"Bankruptcy (Debtor's Petition)", "date"=>"2010-01-04", "role"=>"principal", "discharge_date"=>"2010-01-05", "discharge_status"=>"discharged"},
          {"section"=>"Bankruptcy", "type"=>"Personal Insolvency Agreement (Part 10 Deed)", "date"=>"2012-01-04", "role"=>"principal"}]
          )
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies).to eq("2012-01-04".to_date)
        expect(@response.subsequent_part_ix_or_part_x_bankruptcies.class).to eq(Date)
      end
    end

    describe ".external_administration" do
      it "returns false if not under external administration director" do
        expect(@response.external_administration).to eq(false)
      end
      it "returns true if not under external administration director" do
        @response.stub(:summary_data).and_return({"external_administration_director"=>"1"})
        expect(@response.external_administration).to eq(true)
      end
    end

    describe "paid_defaults" do
      before(:each) do
        @response.stub(:defaults).and_return([{
            "section"=>"Default",
            "account_type" => "Utilities",
            "type"=>"Loan Contract,Settled,Clearout",
            "date"=>"2010-10-05",
            "creditor"=>"ACME GROUP LTD",
            "current_amount"=>"6910",
            "original_amount"=>"6910",
            "role"=>"principal",
            "reference"=>"12345"
          }.with_indifferent_access, {
            "section"=>"Default",
            "account_type" => "Telecommunication Service",
            "type"=>"Loan Contract,Settled,Clearout",
            "date"=>"2011-10-05",
            "creditor"=>"ACME GROUP LTD",
            "current_amount"=>"6910",
            "original_amount"=>"6910",
            "role"=>"principal",
            "reference"=>"12345"
          }.with_indifferent_access, {
            "section"=>"Default",
            "account_type" => "Loan Contract",
            "type"=>"Loan Contract,Settled,Clearout",
            "date"=>"2015-02-05",
            "creditor"=>"ACME GROUP LTD",
            "current_amount"=>"6910",
            "original_amount"=>"6910",
            "role"=>"principal",
            "reference"=>"12345"
          }.with_indifferent_access, {
            "section"=>"Default",
            "account_type" => "Loan Contract",
            "type"=>"Loan Contract,Settled",
            "date"=>"2015-02-05",
            "creditor"=>"ACME GROUP LTD",
            "current_amount"=>"1234",
            "default_amount"=>"1234",
            "original_amount"=>"1234",
            "role"=>"principal",
            "reference"=>"12346",
            "reason_to_report"=>"Payment Default"
          }.with_indifferent_access, {
            "section"=>"Default",
            "account_type" => "Loan Contract",
            "type"=>"Loan Contract,Settled",
            "date"=>"2013-02-05",
            "creditor"=>"ACME GROUP LTD",
            "current_amount"=>"2345",
            "default_amount"=>"2345",
            "original_amount"=>"2345",
            "role"=>"principal",
            "reference"=>"12347",
            "reason_to_report"=>"Payment Default"
          }.with_indifferent_access
        ])
      end

      it ".paid_defaults" do
        expect(@response.paid_defaults.any?).to eq(true)
      end

      it ".paid_defaults_total" do
        expect(@response.paid_defaults_total).to eq(3579)
      end

      # [12, 24, 36, 48, 60, 72].each do |term|
      #   it ".paid_defaults_#{term}_amount"
      # end
    end

    describe "unpaid_defaults" do
      it ".unpaid_defaults"
      it ".unpaid_defaults_total"

      [12, 24, 36, 48, 60, 72].each do |term|
        it ".unpaid_defaults_#{term}_amount"
      end
      [12, 24, 36, 48, 60, 72].each do |term|
        it ".unpaid_defaults_#{term}_count"
      end
    end

    describe "non_credit_defaults" do
      it ".non_credit_clearouts"
      it ".non_credit_clearouts_total"

      [12, 24, 36, 48, 60, 72].each do |term|
        it ".non_credit_clearouts_#{term}_amount"
      end
      [12, 24, 36, 48, 60, 72].each do |term|
        it ".non_credit_clearouts_#{term}_count"
      end
    end

    describe "credit_clearouts" do
      it ".credit_clearouts"
      it ".non_credit_clearouts_total"

      [12, 24, 36, 48, 60, 72].each do |term|
        it ".credit_clearouts_#{term}_amount"
      end
      [12, 24, 36, 48, 60, 72].each do |term|
        it ".credit_clearouts_#{term}_count"
      end
    end
  end

end
