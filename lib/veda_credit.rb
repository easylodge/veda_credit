require 'active_record'
require 'veda_credit/version'
require 'nokogiri'
require 'httparty'
require 'veda_credit/commercial_request'
require 'veda_credit/commercial_response'
require 'veda_credit/consumer_request'
require 'veda_credit/consumer_response'
require 'veda_credit/railtie' if defined?(Rails)

module VedaCredit
end
