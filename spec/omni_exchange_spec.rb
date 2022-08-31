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

  context 'the .get_fx_data' do
    let(:response) do
      VCR.use_cassette('omni_exchange/omni_exchange_get_fx_data', record: :new_episodes) { OmniExchange.get_fx_data(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: [:open_exchange_rates]) }
    end

    it 'returns a hash with the converted amount, an exchange rate, and the data provider' do
      converted_amount = response[:converted_amount]
      exchange_rate = response[:exchange_rate]

      expect(converted_amount).to be_a(BigDecimal)
      expect(exchange_rate).to be_a(BigDecimal)
      expect(response).to be_a(Hash).and contain_exactly([:converted_amount, converted_amount], [:exchange_rate, 0.9521811e1], [:non_subunit_fx_rate, 0.9521811e1], [:provider, :open_exchange_rates])
    end

    context 'when API data is requested from a provider that is not registered in the providers array' do
      let(:response) do
        OmniExchange.get_fx_data(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: ['NOT REGISTERED', :open_exchange_rates])
      end

      it 'breaks without attempting to get API data from another provider' do
        expect { response }.to raise_error(LoadError)
      end
    end

    context 'when the primary data-provider times out' do
      let(:response) do
        VCR.use_cassette('omni_exchange/omni_exchange_timeout', record: :new_episodes) { OmniExchange.get_fx_data(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: ['slow_xe', :open_exchange_rates]) }
      end

      it 'converts an amount of one currency to another currency using a secondary data provider' do
        timed_out_xe = double OmniExchange::Xe
        allow(timed_out_xe).to receive(:get_exchange_rate).and_raise(Faraday::Error, 'slow connection...')
        allow(OmniExchange::Provider).to receive(:load_provider).with('slow_xe').and_return(timed_out_xe)
        allow(OmniExchange::Provider).to receive(:load_provider).with(:open_exchange_rates).and_return(OmniExchange::OpenExchangeRates)

        expect(response[:converted_amount]).to be_a(BigDecimal).and eq(0.9550665e3)
      end
    end

    context 'when all providers time out' do
      let(:response) { OmniExchange.get_fx_data(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: %w[slow_xe slow_open_exchange]) }

      it 'raises a OmniExchange::HttpError' do
        timed_out_xe = double OmniExchange::Xe
        timed_out_open_exchange_rates = double OmniExchange::OpenExchangeRates
        allow(timed_out_xe).to receive(:get_exchange_rate).and_raise(Faraday::Error, 'slow connection...')
        allow(timed_out_open_exchange_rates).to receive(:get_exchange_rate).and_raise(Faraday::Error, 'slow connection...')
        allow(OmniExchange::Provider).to receive(:load_provider).with('slow_xe').and_return(timed_out_xe)
        allow(OmniExchange::Provider).to receive(:load_provider).with('slow_open_exchange').and_return(timed_out_open_exchange_rates)

        expect { response }.to raise_error(OmniExchange::HttpError)
      end
    end

    context 'when there is an unknown or invalid currency' do
      let(:response) { OmniExchange.get_fx_data(amount: 100, base_currency: 'fake_crypto', target_currency: 'fake_currency', providers: [:open_exchange_rates]) }

      it 'raises a OmniExchange::UnknownCurrency' do
        expect { response }.to raise_error(OmniExchange::UnknownCurrency)
      end
    end

    context 'when the primary data-provider returns invalid JSON' do
      let(:response) do
        VCR.use_cassette('omni_exchange/omni_exchange_invalid_json') { OmniExchange.get_fx_data(amount: 100, base_currency: 'JPY', target_currency: 'KRW', providers: ['xe_invalid_json', :open_exchange_rates]) }
      end

      it 'converts an amount of one currency to another currency using a secondary data provider' do
        xe_invalid_json = double OmniExchange::Xe
        allow(xe_invalid_json).to receive(:get_exchange_rate).and_raise(Faraday::Error, 'slow connection...')
        allow(OmniExchange::Provider).to receive(:load_provider).with('xe_invalid_json').and_return(xe_invalid_json)
        allow(OmniExchange::Provider).to receive(:load_provider).with(:open_exchange_rates).and_return(OmniExchange::OpenExchangeRates)
        allow(xe_invalid_json).to receive(:get_exchange_rate).and_raise(JSON::ParserError, 'bad json...')

        expect(response[:converted_amount]).to be_a(BigDecimal).and eq(0.9550665e3)
      end
    end
  end
end
