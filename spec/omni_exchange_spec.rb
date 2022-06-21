# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniExchange do
  let(:xe_api_id) { ENV['XE_API_ID'] }
  let(:xe_api_key) { ENV['XE_API_KEY'] }
  let(:xe_read_timeout) { nil }
  let(:open_exchange_app_id) { ENV['OPEN_EXCHANGE_RATES_APP_ID'] }
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
          app_id: 'test'
        }
      }
    end
  end

  it 'allows configurations to be set with ".configure"' do
    expect(OmniExchange).to respond_to(:configure)
  end

  it 'creates a new instance of Configuration' do
    expect(OmniExchange).not_to be(nil)
  end

  context 'the .exchange_currency method' do
    context 'when API data is requested from a provider that is not registered in the providers array' do
      let(:response) do
        OmniExchange.exchange_currency(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: ['NOT REGISTERED', :open_exchange_rates])
      end

      it 'it expects to break without attempting to get API data from another provider' do
        expect { response }.to raise_error(LoadError)
      end
    end

    context 'when the primary data-provider times out' do
      let(:response) do
        VCR.use_cassette('omni_exchange/omni_exchange_timeout', record: :new_episodes) { OmniExchange.exchange_currency(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: ['slow_xe', :open_exchange_rates]) }
      end

      it 'converts an amount of one currency to another currency using a secondary data provider' do
        timed_out_xe = double OmniExchange::Xe
        allow(timed_out_xe).to receive(:get_exchange_rate).and_raise(Faraday::Error)
        allow(OmniExchange::Provider).to receive(:load_provider).with('slow_xe').and_return(timed_out_xe)
        allow(OmniExchange::Provider).to receive(:load_provider).with(:open_exchange_rates).and_return(OmniExchange::OpenExchangeRates)

        expect(response).to be_a(BigDecimal)
        expect(response).to eq(0.9550665e3)
      end
    end
  end
end
