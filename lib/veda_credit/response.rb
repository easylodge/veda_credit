class VedaCredit::Response < ActiveRecord::Base
  self.table_name = "veda_credit_responses"
  
  belongs_to :request, dependent: :destroy

  serialize :headers
  serialize :struct
  serialize :match

  validates :request_id, presence: true
  validates :xml, presence: true
  validates :headers, presence: true
  validates :code, presence: true
  validates :success, presence: true

  after_initialize :to_struct
  
  def to_hash!
    Hash.from_xml(self.xml)
  end

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
    connection_error = VedaCredit::Response.nested_hash_value(self.to_hash!, "BCAerror")
    product_error = VedaCredit::Response.nested_hash_value(self.to_hash!, "error")
    if connection_error || product_error
      connection_error || product_error
    elsif !self.success? 
      self.xml
    else        
      "No Error"
    end
  end

  def to_struct
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
    fname = File.expand_path('../../lib/assets/Vedascore-individual-enquiries-response-version-1.1.xsd', File.dirname(__FILE__) )
    File.read(fname)
  end

end
