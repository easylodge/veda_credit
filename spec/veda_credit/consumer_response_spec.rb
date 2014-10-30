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
  end
  
  
end
