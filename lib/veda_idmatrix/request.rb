class VedaIdmatrix::Request < ActiveRecord::Base
  self.table_name = "veda_idmatrix_requests"
  has_one :response, dependent: :destroy, inverse_of: :request
  serialize :access
  serialize :entity
  serialize :enquiry

  validates :ref_id, presence: true
  validates :access, presence: true
  validates :entity, presence: true
  validates :enquiry, presence: true

  def schema
    fname = File.expand_path( '../../lib/assets/idmatrix-v4-0-12.xsd', File.dirname(__FILE__) )
    File.read(fname)
  end

  def to_soap
    if self.entity
      self.to_xml_body
      self.soap = self.add_envelope(self.xml, self.access[:url], self.access[:access_code], self.access[:password], 'message_id')
    else
      "No entity details - set your entity hash"
    end
  end

  def to_xml_body
    doc = self.to_dom('request', self.id_matrix_operation, {:'client-reference'=>self.enquiry[:client_reference], :'reason-for-enquiry'=>self.enquiry[:reason_for_enquiry]}).to_xml.gsub(/(<[\/]?)/,'\1idm:')
    self.xml = doc.gsub('<idm:?xml version="1.0"?>','')
  end

  def to_dom(node, data, attrs={})
    doc = Nokogiri::XML::Builder.new do |builder|
      if data.is_a?(Hash) && data.keys.sort == [:attributes, :value]
        attrs.merge!(data[:attributes])
        data = data[:value]
      end

      if data.is_a? Hash
        builder.send(node, attrs) do
          data.keys.each do |k|
            builder << to_dom(k, data[k]).root.to_xml
          end
        end
      else
        builder.send(node, data, attrs)
      end
    end
    doc.doc
  end

  def id_matrix_operation
    individual_name = {
      :'family-name' => (self.entity[:family_name]).to_s,
      :'first-given-name' => (self.entity[:first_given_name]).to_s,
    }
    individual_name = individual_name.merge(:'other-given-name' => (self.entity[:other_given_name]).to_s) if self.entity[:other_given_name].present? #rescue false

    date_of_birth = (self.entity[:date_of_birth]) #.strftime("%Y-%m-%d")
    gender = (self.entity[:gender].downcase)

    if self.entity[:current_address][:unformatted_address]
       current_address = {:'unformatted-address' => self.entity[:current_address][:unformatted_address]}
    else
      current_address = {
        :'property' => (self.entity[:current_address][:property]),
        :'unit-number' => (self.entity[:current_address][:unit_number]),
        :'street-number' => (self.entity[:current_address][:street_number]),
        :'street-name' => (self.entity[:current_address][:street_name]),
        :'street-type' => (self.entity[:current_address][:street_type]),
        :'suburb' => (self.entity[:current_address][:suburb]),
        :'state' => (self.entity[:current_address][:state]),
        :'postcode' => (self.entity[:current_address][:postcode]),
      }
      current_address.delete(:'unit-number') if self.entity[:current_address][:unit_number].blank? #rescue true
    end

    phone = {
      :'numbers' => {
        :'home-phone-number verify="true"' => (self.entity[:home_phone_number]),
        :'mobile-phone-number verify="true"' => (self.entity[:mobile_phone_number])
      }
    }

    email_address = (self.entity[:email_address])

    drivers_licence_details = {
      :'state-code' => (self.entity[:drivers_licence_state_code]),
      :'number' => (self.entity[:drivers_licence_number]),
      :'cardnumber' => (self.entity[:drivers_licence_card_number])
    }

    passport_details = {
      :'country-code' => (self.entity[:passport_country_code]),
      :'number' => (self.entity[:passport_number])
    }

    medicare_details = {}
    unless self.entity[:medicare_card_number].blank?
      medicare_details = {
        :'card-number' => (self.entity[:medicare_card_number]),
        :'reference-number' => (self.entity[:medicare_reference_number]),
        :'middle-name-on-card' => '',
        :'date-of-expiry' => (self.entity[:medicare_card_expiry]),
        :'card-colour' => (self.entity[:medicare_card_color])
      }
      medicare_details[:'middle-name-on-card'] = self.entity[:other_given_name].to_s.capitalize if self.entity[:other_given_name].present?
    end

    # Make sure items generated in order #5519
    details = ActiveSupport::OrderedHash.new
    # details[:'consents'] = consents
    details[:'individual-name'] = individual_name
    details[:'date-of-birth'] = date_of_birth
    details[:'gender'] = gender
    details[:'current-address'] = current_address
    details[:'phone']=  phone
    details[:'email-address'] = email_address
    details[:'drivers-licence-details'] = drivers_licence_details
    details[:'passport-details'] = passport_details
    details[:'medicare'] = medicare_details unless medicare_details.empty?
    details
  end

  def add_envelope(xml_message, url, username, password, message_id)
    "<soapenv:Envelope
      xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
      xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"
      xmlns:wsa=\"http://www.w3.org/2005/08/addressing\"
      xmlns:vh=\"http://vedaxml.com/soap/header/v-header-v1-7.xsd\"
      xmlns:idm=\"http://vedaxml.com/vxml2/idmatrix-v4-0.xsd\">
      <soapenv:Header>
        <wsse:Security>
          <wsse:UsernameToken>
            <wsse:Username>#{username}</wsse:Username>
            <wsse:Password>#{password}</wsse:Password>
          </wsse:UsernameToken>
        </wsse:Security>
        <wsa:ReplyTo>
          <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>
        </wsa:ReplyTo>
        <wsa:To>#{url}</wsa:To>
        <wsa:Action>http://vedaxml.com/idmatrix/VerifyIdentity</wsa:Action>
        <wsa:MessageID>#{message_id}</wsa:MessageID>
      </soapenv:Header>
      <soapenv:Body>#{xml_message}</soapenv:Body>
    </soapenv:Envelope>"
  end

  def validate_xml
    if self.xml
      xsd = Nokogiri::XML::Schema(self.schema)
      doc = Nokogiri::XML(self.xml)
      xsd.validate(doc).each do |error|
        error.message
      end
    else
      "No xml to validate! - run to_soap"
    end
  end

  def post
    self.to_soap
    if self.soap
      headers = {'Content-Type' => 'text/xml', 'Accept' => 'text/xml'}
      HTTParty.post(self.access[:url], :body => self.soap, :headers => headers)
    else
      "No soap envelope to post! - run to_soap"
    end
  end

end
