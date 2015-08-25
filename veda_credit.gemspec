# veda.gemspec
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'veda_credit/version'

Gem::Specification.new do |spec|
  spec.name          = "veda_credit"
  spec.version       = VedaCredit::VERSION
  spec.authors       = ["Andre Mouton"]
  spec.email         = ["andre@amtek.co.za", "info@shuntyard.co.za", "info@easylodge.com.au"]
  spec.summary       = %q{Veda Credit Checks.}
  spec.description   = %q{Veda Credit Checks.}
  spec.homepage      = "https://github.com/easylodge/veda_credit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib","lib/veda"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency 'rails', '~> 4.0.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'pry'
  spec.add_dependency "nokogiri"
  spec.add_dependency "httparty"
  spec.add_dependency 'activesupport'
end
