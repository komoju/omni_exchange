# frozen_string_literal: true

require 'omni_exchange'
require 'faraday'
require 'money'
require 'vcr'
require 'dotenv/load'
require 'pry'
require 'omni_exchange/provider'
require 'omni_exchange/providers/xe'
require 'omni_exchange/providers/open_exchange_rates'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr'
  c.hook_into :faraday
  c.filter_sensitive_data('<app_id>') { ENV['OPEN_EXCHANGE_RATES_APP_ID'] }
end
