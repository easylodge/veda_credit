module VedaCredit
  class Response < ActiveRecord::Base
    self.table_name = "veda_credit_responses"
    self.primary_key = :id

    belongs_to :request, dependent: :destroy

    serialize :headers
    serialize :struct
    serialize :match

    validates :request_id, presence: true
    validates :xml, presence: true

    after_initialize :to_struct!
    
    def to_hash!
      Hash.from_xml(self.xml)
    end

    # def match
    #   match = VedaCredit::Response.nested_hash_value(self.to_hash!, "primary_match")
    #   if match  
    #     RecursiveOpenStruct.new(self.to_hash!["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"])
    #   end
    # end

    def self.nested_hash_value(obj,key)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.respond_to?(:each)
        r = nil
        obj.find{ |*a| r=nested_hash_value(a.last,key) }
        r
      end
    end

    def error
      # connection_error = VedaCredit::Response.nested_hash_value(self.to_hash!, "BCAerror")
      # product_error = VedaCredit::Response.nested_hash_value(self.to_hash!, "error")
      # if connection_error || product_error
      #   connection_error || product_error
      if self.success?
        "No error"
      else
        self.xml
      end
    end

    def to_struct!
      if self.xml
        self.struct = RecursiveOpenStruct.new(self.to_hash!["BCAmessage"])
      end
    end

    def validate_xml
      xsd = Nokogiri::XML::Schema(self.schema)
      doc = Nokogiri::XML(self.xml)
      xsd.validate(doc).each do |error|
        error.message
      end     
    end

    def schema
      fname = File.expand_path(File.dirname(__FILE__) + '/Vedascore-individual-enquiries-response-version-1.1.xsd')
      File.read(fname)
    end
	
  end
end