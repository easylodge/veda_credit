require 'active_record'
require 'equifax_credit/version'
require 'nokogiri'
require 'httparty'
require 'equifax_credit/commercial_request'
require 'equifax_credit/commercial_response'
require 'equifax_credit/consumer_request'
require 'equifax_credit/consumer_response'
require 'equifax_credit/v2/indepth_company_trading_history_request'
require 'equifax_credit/v2/indepth_company_trading_history_response'
require 'equifax_credit/railtie' if defined?(Rails)

module EquifaxCredit
end
