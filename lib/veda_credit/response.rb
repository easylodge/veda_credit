class VedaCredit::Response < ActiveRecord::Base
  self.table_name = "veda_credit_responses"
  
  belongs_to :request, dependent: :destroy

  serialize :headers
  # serialize :as_hash
  
  validates :request_id, presence: true
  validates :xml, presence: true
  validates :headers, presence: true
  validates :code, presence: true
  validates :success, presence: true

  after_initialize :to_hash
  
  def to_hash
    hash = Hash.from_xml(self.xml)
    doc = Nokogiri::XML(self.xml)
    gender_value = (doc.xpath("//gender").first.attributes["type"].value rescue nil)
    role_value = (doc.xpath("//role").first.attributes["type"].value rescue nil)
    gender = (hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"]["individual"]["gender"] rescue nil)
    role = (hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"]["individual_consumer_credit_file"]["credit_enquiry"]["role"] rescue nil)
    gender = gender_value if gender
    role = role_value if role
    hash
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
    connection_error = VedaCredit::Response.nested_hash_value(self.to_hash, "BCAerror")
    product_error = VedaCredit::Response.nested_hash_value(self.to_hash, "error")
    if connection_error || product_error
      connection_error || product_error
    elsif !self.success? 
      self.xml
    else        
      "No Error"
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

  def primary_match
    self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["primary_match"] rescue {}
  end

  def score_data
    self.to_hash["BCAmessage"]["BCAservices"]["BCAservice"]["BCAservice_data"]["response"]["enquiry_report"]["score_data"] rescue {}
  end

  def summary_data
    doc = Nokogiri::XML(self.xml)
    hash = {}
    doc.xpath("//summary").each do |el|
      hash[el.xpath("@name").text] = (el.text.present? ? el.text : "nil") 
    end
    hash
  end

end
