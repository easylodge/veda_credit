class VedaIdmatrix::Response < ActiveRecord::Base
  self.table_name = "veda_idmatrix_responses"
  belongs_to :request, dependent: :destroy, inverse_of: :response

  serialize :headers
  serialize :struct

  def initialize(options={})
    if options[:headers]
      options[:headers] = (options[:headers].to_h rescue {}) unless options[:headers].is_a?(Hash)
    end
    super(options)
  end


  def to_hash
    if self.xml
      Hash.from_xml(self.xml)
    else
      "No hash was created because there was no xml"
    end
  end

  def error
    if self.xml && !self.success?
      self.xml
    else
      "No error"
    end
  end

  def pass
    to_hash["Envelope"]["Body"]["response"]["response_outcome"]["overall_outcome"] rescue "NO DATA"
  end

  def score
    to_hash["Envelope"]["Body"]["response"]["component_responses"]["verification_response"]["verification_outcome"]["total_points"] rescue "0"
   end

  def indicator
    to_hash["Envelope"]["Body"]["response"]["component_responses"]["verification_response"]["verification_outcome"]["indicator"] rescue "N/A"
   end

  def analysis_result
    to_hash["Envelope"]["Body"]["response"]["component_responses"]["verification_response"]["analysis_results"]["analysis_result"] rescue []
  end

  def search_result
    to_hash["Envelope"]["Body"]["response"]["component_responses"]["verification_response"]["search_results"]["search_result"] rescue []
  end

  def idmatrix_error
    "Fault String: #{to_hash["Envelope"]["Body"]["Fault"]["faultstring"]}, Status: #{hash["Envelope"]["Body"]["Fault"]["detail"]["policyResult"]['status']}"  rescue ""
  end
end