require 'spec_helper'

describe VedaIdmatrix::Request do
  it { should have_one(:response).dependent(:destroy) }
  it { should validate_presence_of(:ref_id) }
  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:entity) }
  it { should validate_presence_of(:enquiry) }

  before(:each) do
    @config = YAML.load_file('dev_config.yml')
    @access_hash =
      {
        :url => @config["url"],
        :access_code => @config["access_code"],
        :password => @config["password"]
      }

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
      :phone_authentication_number => "0487654321",
      :send_pin_method => "sms",
      :email_address => "harry.potter@example.com",
      :alternative_email_address => "hpotter@example.com",
      :drivers_licence_state_code => "NSW",
      :drivers_licence_number => "1234567890",
      :drivers_licence_card_number => "123454321",
      :drivers_licence_date_of_expiry => "2000-01-01",
      :drivers_licence_card_number => "1234567890",
      :passport_country_code => "AUS",
      :passport_number => "1234567890",
      :name_at_citizenship => {
        :family_name => "Potter",
        :first_given_name => "Harry",
        :other_given_name => "James"
      },
      :place_of_birth => "Little Whinging",
      :country_of_birth => "AUS",
      :medicare_card_number => "1234567890",
      :medicare_reference_number => "1",
      :medicare_card_expiry => "2000-01",
      :medicare_card_color => "G",
      :birth_cert_reg_number => "12345679890",
      :birth_cert_reg_state =>"NSW",
      :birth_cert_reg_date => "1980-08-02",
      :birth_cert_reg_name => {
        :family_name => "Potter",
        :first_given_name => "Harry",
        :other_given_name => "James"
      },
      :marriage_cert_reg_number => "1234567890",
      :marriage_cert_reg_state => "NSW",
      :marriage_cert_reg_year => "2000",
      :marriage_date => "2000-02-02",
      :brides_name => {
        :family_name => "Wesley",
        :first_given_name => "Ginny"
      },
      :grooms_name => {
        :family_name => "Potter",
        :first_given_name => "Harry",
        :other_given_name => "James"
      },
      :device_intelligence_org_id => "org-abc",
      :device_intelligence_session_id => "X123"
    }

    @enquiry_hash = {
      :client_reference => "123456",
      :reason_for_enquiry => "Test"
    }

    @request = VedaIdmatrix::Request.new(ref_id: 1, access: @access_hash, entity: @entity_hash, enquiry: @enquiry_hash)
  end

  describe "with valid access credentials" do
    before(:each) do
      # prep the soap content
      @request.to_soap
    end

    describe ".access" do
      it "returns not nil" do
        expect(@request.access).to_not be(nil)
      end

      it "can save" do
        @request.save
        expect(@request.access).to_not be(nil)
      end
    end

    describe ".entity" do
      it "returns not nil" do
        expect(@request.entity).to_not be(nil)
      end

      it "can save" do
        @request.save
        expect(@request.entity).to_not be(nil)
      end
    end

    describe ".enquiry" do
      it "returns not nil" do
        expect(@request.enquiry).to_not eq(nil)
      end

      it "can save" do
        @request.save
        expect(@request.enquiry).to_not eq(nil)
      end
    end

    describe ".schema" do
      it "returns the xsd schema" do
        expect(@request.schema).to include('targetNamespace="http://vedaxml.com/vxml2/idmatrix-v4-0.xsd')
      end
    end

    describe ".to_soap" do
      it "returns soap body" do
        expect(@request.to_soap).to_not eq("No entity details - set your entity hash")
      end

      it "sets .soap" do
        @request.to_soap
        expect(@request.soap).to_not eq(nil)
      end

      it "runs on post initialize" do
        allow(HTTParty).to receive(:post).and_return(nil)
        expect(@request).to receive(:to_soap)
        @request.post
      end
    end

    describe ".soap" do
      it "returns soap body" do
        expect(@request.soap).to_not eq(nil)
      end
    end

    describe ".xml" do
      it "returns xml message body" do
        expect(@request.xml).to_not eq(nil)
      end

      it "includes 'client-reference' in xml" do
        expect(@request.xml).to include('idm:request client-reference="123456"')
      end

      it "includes 'reason-for-enquiry' in xml" do
        expect(@request.xml).to include('reason-for-enquiry="Test"')
      end

      it "includes 'family-name' in xml" do
        expect(@request.xml).to include('<idm:family-name>Potter</idm:family-name>')
      end

      it "includes 'first-given-name' in xml" do
        expect(@request.xml).to include('<idm:first-given-name>James</idm:first-given-name>')
      end

      it "includes 'other-given-name' in xml" do
        expect(@request.xml).to include('<idm:other-given-name>Harry</idm:other-given-name>')
      end

      it "includes 'date-of-birth' in xml" do
        expect(@request.xml).to include('<idm:date-of-birth>1980-07-31</idm:date-of-birth>')
      end

      it "includes 'gender' in xml" do
        expect(@request.xml).to include('<idm:gender>male</idm:gender>')
      end

      it "includes 'home-phone-number' in xml" do
        expect(@request.xml).to include('<idm:home-phone-number verify="true">0312345678</idm:home-phone-number>')
      end

      it "includes 'mobile-phone-number' in xml" do
        expect(@request.xml).to include('<idm:mobile-phone-number verify="true">0487654321</idm:mobile-phone-number>')
      end

      it "includes 'email-address' in xml" do
        expect(@request.xml).to include('<idm:email-address>harry.potter@example.com</idm:email-address>')
      end

      it "includes 'drivers-licence-state-code' in xml" do
        expect(@request.xml).to include('<idm:state-code>NSW</idm:state-code>')
      end

      it "includes 'drivers-licence-number' in xml" do
        expect(@request.xml).to include('<idm:number>1234567890</idm:number>')
      end

      describe "without unformatted address as input" do
        before(:each) do
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
                :postcode => "2999"
              },
              :previous_address => {
                :property => "Veda House",
                :unit_number => "15",
                :street_number => "100",
                :street_name => "Arthur",
                :street_type => "Street",
                :suburb => "North Sydney",
                :state => "NSW",
                :postcode => "2060"
              },
              :home_phone_number => "0312345678",
              :mobile_phone_number => "0487654321",
              :work_phone_number => "040012312",
              :phone_authentication_number => "0487654321",
              :send_pin_method => "sms",
              :email_address => "harry.potter@example.com",
              :alternative_email_address => "hpotter@example.com",
              :drivers_licence_state_code => "NSW",
              :drivers_licence_number => "1234567890",
              :drivers_licence_card_number => "123454321",
              :drivers_licence_date_of_expiry => "2000-01-01",
              :drivers_licence_card_number => "1234567890",
              :passport_country_code => "AUS",
              :passport_number => "1234567890",
              :name_at_citizenship => {
                :family_name => "Potter",
                :first_given_name => "Harry",
                :other_given_name => "James"
              },
              :place_of_birth => "Little Whinging",
              :country_of_birth => "AUS",
              :medicare_card_number => "1234567890",
              :medicare_reference_number => "1",
              :medicare_card_expiry => "2000-01",
              :medicare_card_color => "G",
              :birth_cert_reg_number => "12345679890",
              :birth_cert_reg_state =>"NSW",
              :birth_cert_reg_date => "1980-08-02",
              :birth_cert_reg_name => {
                :family_name => "Potter",
                :first_given_name => "Harry",
                :other_given_name => "James"
              },
              :marriage_cert_reg_number => "1234567890",
              :marriage_cert_reg_state => "NSW",
              :marriage_cert_reg_year => "2000",
              :marriage_date => "2000-02-02",
              :brides_name => {
                :family_name => "Wesley",
                :first_given_name => "Ginny"
              },
              :grooms_name => {
                :family_name => "Potter",
                :first_given_name => "Harry",
                :other_given_name => "James"
              },
              :device_intelligence_org_id => "org-abc",
              :device_intelligence_session_id => "X123"
          }
          @request = VedaIdmatrix::Request.new(access: @access_hash, entity: @entity_hash, enquiry: @enquiry_hash)
          @request.to_soap
        end

        it "includes 'property' in xml" do
          expect(@request.xml).to include('<idm:property>Potter Manor</idm:property>')
        end

        it "includes 'unit-number' in xml" do
          expect(@request.xml).to include('<idm:unit-number>3</idm:unit-number>')
        end

        it "includes 'street-number' in xml" do
          expect(@request.xml).to include('<idm:street-number>4</idm:street-number>')
        end

        it "includes 'street-name' in xml" do
          expect(@request.xml).to include('<idm:street-name>Privet</idm:street-name>')
        end

        it "includes 'street-type' in xml" do
          expect(@request.xml).to include('<idm:street-type>Drive</idm:street-type>')
        end

        it "includes 'suburb' in xml" do
          expect(@request.xml).to include('<idm:suburb>Little Whinging</idm:suburb>')
        end

        it "includes 'state' in xml" do
          expect(@request.xml).to include('<idm:state>NSW</idm:state>')
        end

        it "includes 'postcode' in xml" do
          expect(@request.xml).to include('<idm:postcode>2999</idm:postcode>')
        end
      end

      describe "with unformatted address as input" do
        it "uses unformatted address in xml" do
          expect(@request.xml).to include('<idm:unformatted-address>Potter Manor 3/4 Privet Drive Little Whinging NSW 2999</idm:unformatted-address>')
        end
      end
    end

    describe ".to_xml_body" do
      it "returns xml string" do
        expect(@request.to_xml_body.class).to eq(String)
      end

      it "sets .xml" do
        @request.to_xml_body
        expect(@request.xml).to_not eq(nil)
      end
    end

    describe ".id_matrix_operation" do
      it "returns hash" do
        have_key(:bar)
        expect(@request.id_matrix_operation).to have_key(:'date-of-birth')
      end
    end
  end

  describe ".to_dom" do
    it "generates an XML doc from a hash" do
      data = {:example => 123}
      # p @request.to_dom('spec', data).to_xml
      expect(@request.to_dom('spec', data).to_xml).to eq("<?xml version=\"1.0\"?>\n<spec>\n  <example>123</example>\n</spec>\n")
    end

    it "takes optional attributes" do
      data = {:example => 123}
      # p @request.to_dom('spec', data, {:foo => 'bar'}).to_xml
      expect(@request.to_dom('spec', data, {:foo => 'bar'}).to_xml).to eq("<?xml version=\"1.0\"?>\n<spec foo=\"bar\">\n  <example>123</example>\n</spec>\n")
    end

    it "sets attributes passed as :attributes" do
      # data = {:attributes => {:foo => 'bar'}, :example => 123 }
      data = {:example => {:attributes => {:foo => 'bar'}, :value => 123} }
      # p @request.to_dom('spec', data).to_xml
      expect(@request.to_dom('spec', data).to_xml).to eq("<?xml version=\"1.0\"?>\n<spec>\n  <example foo=\"bar\">123</example>\n</spec>\n")
    end

    it "only sets attributes passed as :attributes when :value is present" do
      # data = {:attributes => {:foo => 'bar'}, :example => 123 }
      data = {:example => {:attributes => {:foo => 'bar'}, :not_value => 123} }
      # p @request.to_dom('spec', data).to_xml
      expect(@request.to_dom('spec', data).to_xml).to eq("<?xml version=\"1.0\"?>\n<spec>\n  <example>\n  <attributes>\n  <foo>bar</foo>\n</attributes>\n  <not_value>123</not_value>\n</example>\n</spec>\n")
    end
  end

  describe 'medicare' do
    it 'should exclude if not defined' do
      no_medicare = @entity_hash.dup
      no_medicare[:medicare_card_number] = ''

      @request_no_medicare = VedaIdmatrix::Request.new(access: @access_hash, entity: no_medicare, enquiry: @enquiry_hash)
      expect(@request_no_medicare.to_soap).to_not include('<idm:medicare>')
    end
  end

  describe 'entity request order' do
    it 'generates XML doc in order' do
      data = {:zzz => 98, :xxx=> '765', :mmm => 123, :aaa => 'yo'}
      expect(@request.to_dom('spec', data).to_xml).to eql("<?xml version=\"1.0\"?>\n<spec>\n  <zzz>98</zzz>\n  <xxx>765</xxx>\n  <mmm>123</mmm>\n  <aaa>yo</aaa>\n</spec>\n")
    end
  end
end
