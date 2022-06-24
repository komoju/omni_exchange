# frozen_string_literal: true

require 'omni_exchange/provider'
# in order to make sure that all API data providers are registered correctly,
#   all of the provider files in the providers folder must be required
require 'omni_exchange/providers/open_exchange_rates'
require 'omni_exchange/providers/xe'
require 'omni_exchange/version'
require 'omni_exchange/configuration'
require 'faraday'
require 'json'
require 'bigdecimal/util'

# rubocop:disable Lint/Syntax
module OmniExchange
  class Error < StandardError; end

  # the configuration instance variable is set to the module scope
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= OmniExchange::Configuration.new
  end

  # This method allows you to call OmniExchange.configure with a block that creates a new
  #   instance of OmniExchange::Configuration
  def self.configure
    yield(configuration)
  end

  module_function

  # returns the amount of money in one country's currency when exchanged from an amount of money of another country's
  #   currency using exchange rates data from API providers
  #
  # @param amount: [Integer, #to_d] the amount to exchange (in cents, if applicable to the currency). ie. 1, 10, 100
  # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
  # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
  # @param providers: [Array] an array of symbols of the providers that will be used to get exchange rates API
  #   data. The symbols must be found in the @providers hash in the Provider class (lib/omni_exchange/provider.rb).
  #   ie. xe:, :open_exchange_rates
  # @return [BigDecimal] the amount of the base currency exchanged to the target currency using an exchange rate
  #   provided by one of the data providers in the providers hash. The final amount is returned as a BigDecimal
  #   for precise calculation. If all of the providers in the providers hash fail to retrieve data,
  #   an exception is raised.
  def exchange_currency(amount:, base_currency:, target_currency:, providers:)
    error_messages = []

    # Make sure all providers passed exist. If not, a LoadError is raise and not rescued
    provider_classes = providers.map { |p| OmniExchange::Provider.load_provider(p) }

    # Gracefully hit each provider and fail-over to the next one
    provider_classes.each do |klass|
      rate = klass.get_exchange_rate(base_currency: base_currency, target_currency: target_currency)
    
      return rate * amount.to_d
    rescue Faraday::Error, Faraday::ConnectionFailed => e
      error_messages << e.inspect
    end
    
    raise "Failed to load #{base_currency}->#{target_currency}:\n#{exception_messages.join("\n")}"
  end
end
# rubocop:enable Lint/Syntax
