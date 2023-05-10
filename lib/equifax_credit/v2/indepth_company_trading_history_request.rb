module EquifaxCredit
  module V2
    class IndepthCompanyTradingHistoryRequest < ActiveRecord::Base
      self.table_name = 'veda_credit_commercial_requests'

      has_one :commercial_response, class_name: 'EquifaxCredit::V2::IndepthCompanyTradingHistoryResponse', foreign_key: 'commercial_request_id', dependent: :destroy

      serialize :access
      serialize :service
      serialize :entity
      serialize :enquiry

      validates :ref_id, presence: true
      validates :access, presence: true
      validates :service, presence: true
      validates :entity, presence: true
      validates :enquiry, presence: true

      before_save :to_xml_body

      def to_xml_body
        if access && service && enquiry

          username = access[:username]
          password = access[:password]

          client_ref = ref_id
          reason_for_enquiry = enquiry[:reason_for_enquiry]
          enquiry_id = enquiry[:enquiry_id] || ''
          request_type = enquiry[:request_type] || 'REPORT'

          bureau_reference = enquiry[:bureau_reference]
          role = enquiry[:role]
          acn = entity[:acn]
          cur_and_hist = enquiry[:current_and_history] || 'current'
          enquiry_type = enquiry[:enquiry_type] || 'credit-enquiry' # credit-enquiry, credit-review
          account_type_code = enquiry[:account_type_code] # HIREPURCHASE
          account_type = enquiry[:account_type] # HC
          currency = enquiry[:currency_code] || 'AUD'
          amount = enquiry[:enquiry_amount]
          credit_type = enquiry[:credit_type] || 'COMMERCIAL'
          link_limit = enquiry[:link_limit] || 0 # 100
          ppsr = enquiry[:ppsr_required] || 'no'

          soap_xml =
            "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:com=\"http://vedaxml.com/vxml2/indepth-company-trading-history-v3-2.xsd\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
              <soapenv:Header>
                <wsse:Security mustUnderstand=\"1\" xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\">
                  <wsse:UsernameToken>
                    <wsse:Username>#{username}</wsse:Username>
                    <wsse:Password>#{password}</wsse:Password>
                  </wsse:UsernameToken>
                </wsse:Security>
                <wsa:MessageID>urn:example.com:123456789</wsa:MessageID>
                <wsa:To>https://vedaxml.com/sys2/indepth-company-trading-history-v3-2</wsa:To>
                <wsa:Action>http://vedaxml.com/indepthCompanyTradingEnquiry/ServiceRequest</wsa:Action>
              </soapenv:Header>
              <soapenv:Body>
                <com:request client-reference=\"#{client_ref}\" reason-for-enquiry=\"#{reason_for_enquiry}\" enquiry-id=\"#{enquiry_id}\" request-type=\"#{request_type}\" >
                  <com:bureau-reference>#{bureau_reference}</com:bureau-reference>
                  <com:subject role=\"#{role}\">
                    <com:australian-company-number>#{acn}</com:australian-company-number>
                  </com:subject>
                  <com:current-historic-flag>#{cur_and_hist}</com:current-historic-flag>
                  <com:enquiry type=\"#{enquiry_type}\">
                    <com:account-type code=\"#{account_type_code}\">#{account_type}</com:account-type>
                    <com:enquiry-amount currency-code=\"#{currency}\">#{amount}</com:enquiry-amount>
                    <com:client-reference>#{client_ref}</com:client-reference>
                  </com:enquiry>
                  <com:collateral-information>
                    <com:credit-type>#{credit_type}</com:credit-type>
                    <com:link-limit>#{link_limit}</com:link-limit>
                    <com:ppsr-required>#{ppsr}</com:ppsr-required>
                  </com:collateral-information>
                </com:request>
              </soapenv:Body>
            </soapenv:Envelope>"
          self.xml = soap_xml
        else
          'Requires access, service or enquiry hash'
        end
      end

      def validate_xml
        xsd = Nokogiri::XML::Schema(schema)
        doc = Nokogiri::XML(xml).remove_namespaces!
        xsd.validate(doc).each(&:message)
      end

      def schema
        fname = File.expand_path('../../lib/assets/indepth-company-trading-history-v3-2.xsd', File.dirname(__FILE__))
        File.read(fname)
      end

      def post
        if access
          headers = { 'Content-Type' => 'text/xml', 'Accept' => 'text/xml' }
          HTTParty.post(access[:url], body: to_xml_body, headers: headers, timeout: access[:timeout])
        else
          'No access hash!'
        end
      end

      def to_s
        'Equifax Credit Indepth Company Trading History Request'
      end
    end
  end
end
