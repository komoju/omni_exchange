# frozen_string_literal: true

require 'spec_helper'
require 'pry'

RSpec.describe OmniExchange::Xe do
  subject(:xe) { OmniExchange::Xe }
  let(:xe_api_id) { ENV['XE_API_ID'] }
  let(:xe_api_key) { ENV['XE_API_KEY'] }
  let(:xe_read_timeout) { nil }
  let(:xe_connect_timeout) { nil }

  before do
    OmniExchange.configure do |config|
      config.provider_config = {
        xe: {
          read_timeout: xe_read_timeout,
          connect_timeout: xe_connect_timeout,
          api_id: 'test',
          api_key: 'test'
        }
      }
    end
  end

  context 'self.get_exchange_rate' do
    let(:response) do
      VCR.use_cassette('omni_exchange/xe_unregistered_provider', record: :new_episodes) { subject.get_exchange_rate(base_currency: 'JPY', target_currency: 'KRW') }
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
  end
end
