require 'spec_helper'

describe VedaCredit::Request do
  it { should have_one(:response).dependent(:destroy) }
  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:product) }
  it { should validate_presence_of(:entity) }
  it { should validate_presence_of(:enquiry) }


  describe "with developer veda credit config file" do
    
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
    
      @product_hash = 
        {
          :service_code => "VDA001",
          :service_code_version => 'V00',
          :request_version => '1.0',
          :product_name => "vedascore-financial-consumer-1.1",
          :summary => "yes"
        }

      @entity_hash = 
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

      @enquiry_hash =
              {
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

      @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
    
    end
    
    describe "with valid inputs" do

    

      it "is valid" do
        expect(@request.valid?).to eq(true)
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

      describe ".product" do
        it "returns product details hash used to build request" do
          expect(@request.product).to eq({
                                    :service_code => "VDA001",
                                    :service_code_version => 'V00',
                                    :request_version => '1.0',
                                    :product_name => "vedascore-financial-consumer-1.1",
                                    :summary => "yes"
                                  })
        end
      end

      describe ".entity" do
        it "returns entity details hash used to build request" do
          expect(@request.entity).to eq({
                                    :family_name => 'Verry',
                                    :first_given_name => 'Dore',
                                    :employer => 'Veda',
                                    :address_type => 'residential-current',
                                    :street_name => "Arthur",
                                    :suburb => "North Sydney",
                                    :state => "NSW",
                                    :gender_type => 'male'
                                  })
        end
      end

      describe ".enquiry" do
        it "returns enquiry details hash used to build request" do
          expect(@request.enquiry).to eq({
                                    :enquiry_type => 'credit-application',
                                    :account_type_code => 'LC',
                                    :currency_code => 'AUD',
                                    :enquiry_amount => '5000',
                                    :client_reference => '123456789'
                                  })
        end
      end

      describe ".struct" do
        it "returns struct of xml body" do
          expect(@request.struct.class).to eq(RecursiveOpenStruct)
        end

        it "accesses nested attributes" do
          expect(@request.struct.type).to eq('REQUEST')
        end
      end

  		describe ".xml" do
        it "returns a xml request" do
  				expect(@request.xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
  			end

        it "includes access code" do
          expect(@request.xml).to include("<BCAaccess-code>#{@config["access_code"]}</BCAaccess-code>")
        end

        it "includes password" do
          expect(@request.xml).to include("<BCAaccess-pwd>#{@config["password"]}</BCAaccess-pwd>")
        end

        it "includes subscriber_id" do
          expect(@request.xml).to include("subscriber-identifier>#{@config["subscriber_id"]}</subscriber-identifier>")
        end

        it "includes security code" do
          expect(@request.xml).to include("<security>#{@config["security_code"]}</security>")
        end

        it "includes mode" do
          expect(@request.xml).to include(%Q{<request version="1.0" mode="#{@config["request_mode"]}">})
        end

        
      end

  		describe ".schema" do
  			it "returns xml schema" do
  				expect(@request.schema).to include('<?xml version="1.0" encoding="UTF-8"?>')
  			end
  		end

  		describe ".validate_xml" do
  				it 'returns empty array' do
  				expect(@request.validate_xml).to eq([])
  			end
  		end
  	

   		describe ".post" do
   			describe "post the request to Veda" do
  				before do
            @req = @request.post
          end

  				it "returns status code 200" do
  					expect(@req.code).to eq(200)
          end

  				it "returns response from veda" do
  				  expect(@req.body).to include('<?xml version="1.0"?>')
  				end
  			end
      end
  	end
    


    describe "with invalid post credentials" do
      describe ".post" do
        describe "post the request to Veda" do
          before do

            @access_hash = 
                    {
                      :url => @config["url"],
                      :access_code => 'xxxxxxx',
                      :password => 'xxxxxxx',
                      :subscriber_id => @config["subscriber_id"],
                      :security_code => @config["security_code"],
                      :request_mode => @config["request_mode"]
                      }

          

            @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash) 
          
            @req = @request.post
          end

          it "returns status code 200" do
            expect(@req.code).to eq(200)
          end

          it "returns response from veda" do
            expect(@req.body).to include('The Request Manager was unable to authenticate the VedaXML access code and password supplied. Check values of: /BCAmessage/BCAaccess/BCAaccess-code and /BCAmessage/BCAaccess/BCAaccess-pwd')
          end
        end
      end

    end 
  end

end

