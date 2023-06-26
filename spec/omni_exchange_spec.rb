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

  describe '.get_exchange_rate' do
    it 'gets the exchange rate from the first provider' do
      expect(OmniExchange::OpenExchangeRates).to receive(:get_exchange_rate).and_call_original
      expect(OmniExchange::Xe).not_to receive(:get_exchange_rate)
      VCR.use_cassette('omni_exchange/open_exchange_rates_exchange_rate') do
        response = OmniExchange.get_exchange_rate(base_currency: 'USD',
                                                  target_currency: 'EUR',
                                                  providers: [:open_exchange_rates, :xe])

        expect(response).to eq(BigDecimal('0.918119e-2'))
      end
    end

    it 'falls back to the second provider if the first provider fails' do
      timed_out_xe = double OmniExchange::Xe
      allow(timed_out_xe).to receive(:get_exchange_rate)
        .and_raise(Faraday::Error, 'slow connection...')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:slow_xe)
        .and_return(timed_out_xe)
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:open_exchange_rates)
        .and_return(OmniExchange::OpenExchangeRates)

      expect(OmniExchange::OpenExchangeRates).to receive(:get_exchange_rate).and_call_original
      VCR.use_cassette('omni_exchange/open_exchange_rates_exchange_rate') do
        response = OmniExchange.get_exchange_rate(base_currency: 'USD',
                                                  target_currency: 'EUR',
                                                  providers: [:slow_xe, :open_exchange_rates])

        expect(response).to eq(BigDecimal('0.918119e-2'))
      end
    end

    it 'raises an error if all providers fail' do
      timed_out_xe = double OmniExchange::Xe
      allow(timed_out_xe).to receive(:get_exchange_rate)
        .and_raise(Faraday::Error, 'slow connection...')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:slow_xe)
        .and_return(timed_out_xe)

      failed_oer = double OmniExchange::OpenExchangeRates
      allow(failed_oer).to receive(:get_exchange_rate)
        .and_raise(Net::ReadTimeout, 'I can not read this')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:failed_oer)
        .and_return(failed_oer)

      expect do
        OmniExchange.get_exchange_rate(base_currency: 'USD',
                                       target_currency: 'EUR',
                                       providers: [:slow_xe, :failed_oer])
      end.to raise_error(OmniExchange::HttpError)
    end
  end

  describe '.get_historic_rate' do
    it 'gets the historic rate for a given date from the first provider' do
      expect(OmniExchange::OpenExchangeRates).not_to receive(:get_historic_rate)
      VCR.use_cassette('omni_exchange/xe_historic_rate') do
        response = OmniExchange.get_historic_rate(date: Date.new(2017, 0o1, 0o1),
                                                  base_currency: 'USD',
                                                  target_currencies: %w[JPY KRW EUR],
                                                  providers: [:xe, :open_exchange_rates])

        expect(response.keys).to match_array(%w[JPY KRW EUR])

        expect(response['JPY']).to eq(0.1169695e1)
        expect(response['KRW']).to eq(0.120726e2)
        expect(response['EUR']).to eq(0.95034e-2)
      end
    end

    it 'falls back to the second provider if the first provider fails' do
      timed_out_xe = double OmniExchange::Xe
      allow(timed_out_xe).to receive(:get_historic_rate)
        .and_raise(Faraday::Error, 'slow connection...')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:slow_xe)
        .and_return(timed_out_xe)
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:open_exchange_rates)
        .and_return(OmniExchange::OpenExchangeRates)

      expect(OmniExchange::OpenExchangeRates).to receive(:get_historic_rate).and_call_original

      VCR.use_cassette('omni_exchange/open_exchange_rates_historic_rate') do
        response = OmniExchange.get_historic_rate(date: Date.new(2017, 0o1, 0o1),
                                                  base_currency: 'USD',
                                                  target_currencies: %w[JPY KRW EUR],
                                                  providers: [:slow_xe, :open_exchange_rates])

        expect(response.keys).to match_array(%w[JPY KRW EUR])

        expect(response['JPY']).to eq(BigDecimal('0.11682243628e1'))
        expect(response['KRW']).to eq(BigDecimal('0.120645e2'))
        expect(response['EUR']).to eq(BigDecimal('0.949713e-2'))
      end
    end

    it 'raises an error if all providers fail' do
      timed_out_xe = double OmniExchange::Xe
      allow(timed_out_xe).to receive(:get_historic_rate)
        .and_raise(Faraday::Error, 'slow connection...')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:slow_xe)
        .and_return(timed_out_xe)

      failed_oer = double OmniExchange::OpenExchangeRates
      allow(failed_oer).to receive(:get_historic_rate)
        .and_raise(Net::ReadTimeout, 'I can not read....')
      allow(OmniExchange::Provider).to receive(:load_provider)
        .with(:failed_oer)
        .and_return(failed_oer)

      expect do
        OmniExchange.get_historic_rate(date: Date.new(2017, 0o1, 0o1),
                                       base_currency: 'USD',
                                       target_currencies: %w[JPY KRW EUR],
                                       providers: [:slow_xe, :failed_oer])
      end.to raise_error(OmniExchange::HttpError)
    end
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
