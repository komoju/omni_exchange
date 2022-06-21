# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniExchange::VERSION do
  it 'has a version number' do
    expect(OmniExchange::VERSION).not_to be nil
  end
end
