# equifax_gem.gemspec
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'equifax'
  spec.version       = '1.0.0'
  spec.authors       = ['Andre Mouton', 'Barry Mieny']
  spec.email         = ['andre@amtek.co.za', 'info@shuntyard.co.za', 'info@easylodge.com.au']
  spec.summary       = 'Veda Credit Checks and Veda IDMatrix Identity Verification.'
  spec.description   = 'Veda Credit Checks and Veda IDMatrix Identity Verification service.'
  spec.homepage      = 'https://github.com/easylodge/equifax'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'lib/veda']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rails', '~> 4.0.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'pry'
  spec.add_dependency 'veda_credit', '>= 0.0.50'
  spec.add_dependency 'veda_idmatrix', '~> 0.0.8'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'httparty'
  spec.add_dependency 'activesupport'
end
