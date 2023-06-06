# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniExchange::OpenExchangeRates do
  subject(:open_exchange_rates) { OmniExchange::OpenExchangeRates }
  let(:open_exchange_rates_read_timeout) { nil }
  let(:open_exchange_rates_connect_timeout) { nil }
  let(:open_exchange_app_id) { ENV['OPEN_EXCHANGE_RATES_APP_ID'] || '<app_id>' }

  before do
    OmniExchange.configure do |config|
      config.provider_config = {
        open_exchange_rates: {
          read_timeout: open_exchange_rates_read_timeout,
          connect_timeout: open_exchange_rates_read_timeout,
          app_id: open_exchange_app_id
        }
      }
    end
  end

  describe '.get_exchange_rate' do
    let(:open_exchange_rates_read_timeout) { 0 }
    let(:open_exchange_rates_connect_timeout) { 0 }
    let(:response) do
      VCR.use_cassette('omni_exchange/open_exchange_rates_unregistered_provider', record: :new_episodes) do
        subject.get_exchange_rate(base_currency: 'USD', target_currency: 'JPY')
      end
    end

    it 'sets "amount_to_multiply_exchange_rate_by" correctly for currencies that use cents' do
      expect(subject.get_currency_unit('USD')).to eq(0.01)
    end

    it 'sets "amount_to_multiply_exchange_rate_by" correctly for currencies that do not use cents' do
      expect(subject.get_currency_unit('JPY')).to eq(1)
    end

    context 'when there is a read timeout' do
      it 'raises a Faraday::Error' do
        expect { response }.to raise_error(Faraday::Error)
      end
    end

    context 'when there is a connection open timeout' do
      it 'raises a Faraday::ConnectionFailed if there is a connection open timeout' do
        expect { response }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context 'when JSON from Open Exchange Rates is invalid' do
      it 'raises a JSON::ParserError' do
        allow(OmniExchange::OpenExchangeRates).to receive(:get_exchange_rate).
          and_raise(JSON::ParserError, 'invalid json...')

        expect { response }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '.get_historic_rate' do
    it 'returns the exchange rates from the date specified' do
      VCR.use_cassette('omni_exchange/open_exchange_rates_historic_rate') do
        rate = subject.get_historic_rate(base_currency: 'USD',
                                         target_currencies: ['EUR', 'JPY', 'KRW'],
                                         date: Date.new(2018, 01, 01)
                                        )

        expect(rate).to eq({
          'EUR' => BigDecimal('0.832586e-2'),
          'JPY' => BigDecimal('0.1127745e1'),
          'KRW' => BigDecimal('0.106625e2'),
        })
      end
    end
  end
end
