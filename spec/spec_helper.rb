require 'bundler/setup'
require 'veda_credit'
require 'shoulda/matchers'
require 'pry'

Bundler.setup

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
require 'schema'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
