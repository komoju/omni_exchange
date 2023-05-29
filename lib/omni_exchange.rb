# frozen_string_literal: true

require 'omni_exchange/provider'
# in order to make sure that all API data providers are registered correctly,
#   all of the provider files in the providers folder must be required
require 'omni_exchange/providers/open_exchange_rates'
require 'omni_exchange/providers/xe'
require 'omni_exchange/version'
require 'omni_exchange/configuration'
require 'omni_exchange/error'
require 'faraday'
require 'money'
require 'json'
require 'bigdecimal/util'
require 'net/http'

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

  # if a provider raises one of these exceptions, OmniExchange will gracefully attempt to use another provider
  EXCEPTIONS = [Faraday::Error, Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError, Net::OpenTimeout, Net::WriteTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError]

  module_function

  # returns foreign exchange data including the amount of money in one country's currency when exchanged from an
  #   amount of money of another country's currency using exchange rates data from API providers, the exchange
  #   rate used to calculate that amount, and the API provider that supplied that rate.
  #
  # @param amount: [Integer, #to_d] the amount to exchange (in cents, if applicable to the currency). ie. 1, 10, 100
  # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
  # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
  # @param providers: [Array] an array of symbols of the providers that will be used to get exchange rates API
  #   data. The symbols must be found in the @providers hash in the Provider class (lib/omni_exchange/provider.rb).
  #   ie. xe:, :open_exchange_rates
  # @return [Hash] If none of the providers in the providers hash are able to retrieve data, or if one of the
  #   currencies is not valid, an exception is raised.
  #   * :converted_amount [BigDecimal] the amount of money exchanged from the base currency to the target
  #       currency as a BigDecimal for precice calculation. ie. 1, 10, 100
  #   * :exchange_rate [BigDecimal] the rate used to calculate the converted_amount as a BigDecimal. ie. 0.95211e1
  #   * :non_subunit_fx_rate [BigDecimal] a rate that can be used when a currency with subunits is not in cents . ie. 0.95211e3
  #   * :provider [Symbol] the provider that supplied the exchange_rate data. ie. :xe, :open_exchange_rates
  def get_fx_data(amount:, base_currency:, target_currency:, providers:)
    # if one of the currencies is not valid (ie. 'fake_crypto'), an exception is raised.
    begin
      Money::Currency.wrap(base_currency)
      Money::Currency.wrap(target_currency)
    rescue Money::Currency::UnknownCurrency => exception
      raise OmniExchange::UnknownCurrency, "#{exception}"
    end

    error_messages = []

    # Make sure all providers passed exist. If not, a LoadError is raise and not rescued
    provider_classes = providers.map { |p| OmniExchange::Provider.load_provider(p) }

    # Gracefully hit each provider and fail-over to the next one
    provider_classes.each do |klass|
      rate = klass.get_exchange_rate(base_currency: base_currency, target_currency: target_currency)
      plain_format_rate = (rate * Money::Currency.wrap(base_currency).subunit_to_unit).to_d

      exchanged_amount = rate.to_d * amount.to_d

      return { converted_amount: exchanged_amount, exchange_rate: rate, non_subunit_fx_rate: plain_format_rate, provider: OmniExchange::Provider.all.key(klass) }
    rescue *EXCEPTIONS, OmniExchange::XeMonthlyLimit, JSON::ParserError => e
      error_messages << e.inspect
    end

    raise OmniExchange::HttpError, "Failed to load #{base_currency}->#{target_currency}:\n#{error_messages.join("\n")}"
  end
end
# rubocop:enable Lint/Syntax
