# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniExchange::Configuration do
  let(:xe_api_id) { 'abcdefg' }
  let(:xe_api_key) { 'abcdefg' }
  let(:xe_read_timeout) { nil }
  let(:open_exchange_app_id) { 'abcdefg' }
  let(:open_exchange_rates_read_timeout) { nil }

  before do
    OmniExchange.configure do |config|
      config.provider_config = {
        xe: {
          read_timeout: xe_read_timeout,
          api_id: xe_api_id,
          api_key: xe_api_key
        },
        open_exchange_rates: {
          read_timeout: open_exchange_rates_read_timeout,
          app_id: open_exchange_app_id
        }
      }
    end
  end

  it 'provides access to configuration settings' do
    expect(OmniExchange.configuration.provider_config[:open_exchange_rates][:app_id]).to eq('abcdefg')
    expect(OmniExchange.configuration.provider_config[:xe][:api_key]).to eq('abcdefg')
  end
end
