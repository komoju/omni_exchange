# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniExchange::Provider do
  it 'registers all of the providers in the providers folder' do
    expect(OmniExchange::Provider.all).to include(:xe, :open_exchange_rates)
  end

  it 'raises a LoadError if the user attempts to load an unregistered provider' do
    provider = 'unregistered provider'

    expect { OmniExchange::Provider.load_provider(provider) }.to raise_error(LoadError)
  end

  context 'the .get_currency_unit method' do
    it "uses the RubyMoney gem to get a currency's subunit" do
      expect(OmniExchange::Provider.get_currency_unit('USD')).to be_a(Float).and eq(0.01)
      expect(OmniExchange::Provider.get_currency_unit('JPY')).to be_a(Float).and eq(1.0)
    end
  end
end
