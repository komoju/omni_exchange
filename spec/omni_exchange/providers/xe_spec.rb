# frozen_string_literal: true

require 'spec_helper'
require 'pry'

RSpec.describe OmniExchange::Xe do
  subject(:xe) { OmniExchange::Xe }
  let(:xe_read_timeout) { nil }
  let(:xe_connect_timeout) { nil }

  before do
    OmniExchange.configure do |config|
      config.provider_config = {
        xe: {
          read_timeout: xe_read_timeout,
          connect_timeout: xe_connect_timeout,
          api_id: ENV['XE_API_ID'],
          api_key: ENV['XE_API_KEY']
        }
      }
    end
  end

  describe '.get_exchange_rate' do
    let(:response) do
      VCR.use_cassette('omni_exchange/xe_unregistered_provider', record: :new_episodes) do
        subject.get_exchange_rate(base_currency: 'JPY', target_currency: 'KRW')
      end
    end

    it 'sets "amount_to_multiply_exchange_rate_by" correctly for currencies that use cents' do
      expect(subject.get_currency_unit('USD')).to eq(0.01)
    end

    it 'sets "amount_to_multiply_exchange_rate_by" correctly for currencies that do not use cents' do
      expect(subject.get_currency_unit('JPY')).to eq(1)
    end

    context 'when there is a read timeout' do
      let(:xe_read_timeout) { 0 }
      it 'raises a Faraday::Error' do
        expect { response }.to raise_error(Faraday::Error)
      end
    end

    context 'when there is a connection open timeout' do
      let(:xe_connect_timeout) { 0 }
      it 'raises a Faraday::ConnectionFailed exception' do
        expect { response }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context "when you have exceeded xe.com's monthly request limit" do
      let(:request) { subject.get_exchange_rate }

      it 'raises an OmniExchange::XeMonthlyLimit exception' do
        allow(subject).to receive(:get_exchange_rate).and_raise(OmniExchange::XeMonthlyLimit)

        expect { request }.to raise_error(OmniExchange::XeMonthlyLimit)
      end
    end

    context 'when JSON from Xe.com is invalid' do
      it 'raises a JSON::ParserError' do
        allow(OmniExchange::Xe).to receive(:get_exchange_rate).and_raise(JSON::ParserError, 'invalid json...')

        expect { response }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '.get_historic_rate' do
    it 'returns the exchange rates from the date specified' do
      VCR.use_cassette('omni_exchange/xe_historic_rate') do
        rate = subject.get_historic_rate(base_currency: 'USD',
                                         target_currencies: ['EUR', 'JPY', 'KRW'],
                                         date: Date.new(2018, 01, 01)
                                        )

        expect(rate).to eq({
          'EUR' => 0.8331756500000001e-2,
          'JPY' => 0.11270502279e1,
          'KRW' => 0.106626496918e2,
        })
      end
    end
  end
end
