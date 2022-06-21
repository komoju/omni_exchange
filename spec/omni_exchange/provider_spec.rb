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
end
