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
    
      

      @entity_hash = 
              {
                :family_name => 'Verry',
                :first_given_name => 'Dore',
                :employer => 'Veda',
                :address_type => 'residential-current',
                :street_name => "Arthur",
                :suburb => "North Sydney",
                :state => "NSW",
                :country_code => 'AU',
                :gender_type => 'male'
                
              }

      
    
    end
    
    describe "with valid access_hash" do

      describe "credit application individual - principal" do

        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'principal',   
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
        end

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
                                      :country_code => "AU",
                                      :gender_type => 'male'
                                    })
          end
        end

        describe ".enquiry" do
          it "returns enquiry details hash used to build request" do
            expect(@request.enquiry).to eq({
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

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-application">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
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
    	
        # works 
     		# describe ".post" do
     		# 	describe "post the request to Veda" do
    			# 	it "returns response from veda" do
    			# 	  expect(@request.post).to be(nil)
    			# 	end
    			# end
       #  end
      end

      describe "credit application individual - co-borrower" do

        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'co-borrower',   
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
        end

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
                                      :country_code => "AU",
                                      :gender_type => 'male'
                                    })
          end
        end

        describe ".enquiry" do
          it "returns enquiry details hash used to build request" do
            expect(@request.enquiry).to eq({
                                      :role=>"co-borrower",
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

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-application">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
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
      
        # works 
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post).to be(nil)
        #     end
        #   end
        # end
      end

      describe "credit application individual - joint" do

        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'joint',   
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
        end

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
                                      :country_code => "AU",
                                      :gender_type => 'male'
                                    })
          end
        end

        describe ".enquiry" do
          it "returns enquiry details hash used to build request" do
            expect(@request.enquiry).to eq({
                                      :role=>"joint",
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

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-application">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
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
      
         
        # works
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post).to be(nil)
        #     end
        #   end
        # end
      end

      describe "credit application individual - guarantor" do

        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'guarantor',   
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
        end

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
                                      :country_code => "AU",
                                      :gender_type => 'male'
                                    })
          end
        end

        describe ".enquiry" do
          it "returns enquiry details hash used to build request" do
            expect(@request.enquiry).to eq({
                                      :role=>"guarantor",
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

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-application">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
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
      
        # works 
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post).to be(nil)
        #     end
        #   end
        # end
      end

      describe "credit application individual - director" do

        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-plus-commercial-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'director',   
                :enquiry_type => 'credit-enquiry',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)        
        end

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
                                      :product_name => "vedascore-financial-consumer-plus-commercial-1.1",
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
                                      :country_code => "AU",
                                      :gender_type => 'male'
                                    })
          end
        end

        describe ".enquiry" do
          it "returns enquiry details hash used to build request" do
            expect(@request.enquiry).to eq({
                                      :role=>"director",
                                      :enquiry_type => 'credit-enquiry',
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

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-enquiry">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
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
      
         
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post).to be(nil)
        #     end
        #   end
        # end
      end

      describe "credit enquiry commercial plus consumer" do 
        before do 
          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-commercial-plus-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'joint',  
                :enquiry_type => 'credit-enquiry',
                :account_type_code => 'CR',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)
        end

        describe ".validate_xml" do
            it 'returns empty array' do
            expect(@request.validate_xml).to eq([])
          end
        end

        describe ".xml" do
          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-enquiry">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="CR"/>')
          end
         
        end

        
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post.code).to be(200)
        #     end
        #   end
        # end
    	end

      describe "credit enquiry commercial" do 
        before do

          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-commercial-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'director',    
                :enquiry_type => 'credit-enquiry',
                :account_type_code => 'CR',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)
        end

        describe ".validate_xml" do
          it 'returns empty array' do
            expect(@request.validate_xml).to eq([])
          end
        end

        describe ".xml" do
          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-enquiry">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="CR"/>')
          end
         
        end
      end

      describe "bureau reference" do 
        before do

          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }

          @enquiry_hash =
              {
                :role => 'principal',    
                :enquiry_type => 'credit-enquiry',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @bureau_reference = "186492371"
           
          @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, bureau_reference: @bureau_reference, enquiry: @enquiry_hash)
        end

        describe ".validate_xml" do
          it 'returns empty array' do
            expect(@request.validate_xml).to eq([])
          end
        end

        describe ".xml" do
          # it "includes xml" do
          #   expect(@request.xml).to be(nil)
          # end

          it "includes enquiry type" do
            expect(@request.xml).to include('<enquiry type="credit-enquiry">')
          end

          it "includes account type" do
            expect(@request.xml).to include('<account-type code="LC"/>')
          end
        end
      
        # describe ".post" do
        #   describe "post the request to Veda" do
        #     it "returns response from veda" do
        #       expect(@request.post).to be(nil)
        #     end
        #   end
        # end

      end
    

      describe "with nested entity hash" do 
        before do 
          @entity_hash = {
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
            :unformatted_address => "Potter Manor 3/4 Privet Drive Little Whinging NSW 2999"
          },
          :previous_address => {
            :property => "Veda House",
            :unit_number => "15",
            :street_number => "100",
            :street_name => "Arthur",
            :street_type => "Street",
            :suburb => "North Sydney",
            :state => "NSW",
            :postcode => "2060",
            :unformatted_address => "Veda House 15/100 Arthur Street North Sydney NSW 2060"
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
                :role => 'principal',   
                :enquiry_type => 'credit-application',
                :account_type_code => 'LC',
                :currency_code => 'AUD',
                :enquiry_amount => '5000',
                :client_reference => '123456789'
              }

          @product_hash = 
            {
              :service_code => "VDA001",
              :service_code_version => 'V00',
              :request_version => '1.0',
              :product_name => "vedascore-financial-consumer-1.1",
              :summary => "yes"
            }    
        @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash)

        end

        describe ".access" do 
          it "is not nil" do 
            expect(@request.access).to_not eq(nil)
          end
        end

        describe ".product" do 
          it "is not nil" do 
            expect(@request.product).to_not eq(nil)
          end
        end

        describe ".entity" do 
          it "is not nil" do 
            expect(@request.entity).to_not eq(nil)
          end
        end

        describe ".enquiry" do 
          it "is not nil" do 
            expect(@request.enquiry).to_not eq(nil)
          end
        end

        describe ".bureau_reference" do 
          it "is not nil" do 
            expect(@request.bureau_reference).to eq(nil)
          end
        end


        describe ".validate_xml" do
            it 'returns empty array' do
            expect(@request.validate_xml).to eq([])
          end
        end



        describe ".xml" do
         
          it "returns xml" do
            expect(@request.xml).to be(nil)
          end
         
        end

      end



    # describe "with invalid post credentials" do
    #   describe ".post" do
    #     describe "post the request to Veda" do
    #       before do

    #         @access_hash = 
    #                 {
    #                   :url => @config["url"],
    #                   :access_code => 'xxxxxxx',
    #                   :password => 'xxxxxxx',
    #                   :subscriber_id => @config["subscriber_id"],
    #                   :security_code => @config["security_code"],
    #                   :request_mode => @config["request_mode"]
    #                   }

          

    #         @request = VedaCredit::Request.new(access: @access_hash, product: @product_hash, entity: @entity_hash, enquiry: @enquiry_hash) 
          
    #         @req = @request.post
    #       end

    #       it "returns status code 200" do
    #         expect(@req.code).to eq(200)
    #       end

    #       it "returns response from veda" do
    #         expect(@req.body).to include('The Request Manager was unable to authenticate the VedaXML access code and password supplied. Check values of: /BCAmessage/BCAaccess/BCAaccess-code and /BCAmessage/BCAaccess/BCAaccess-pwd')
    #       end
    #     end
    #   end

    end 
  end

end

