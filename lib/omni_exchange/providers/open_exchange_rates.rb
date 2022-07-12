# frozen_string_literal: true

require 'omni_exchange'

module OmniExchange
  class OpenExchangeRates < Provider
    ENDPOINT_URL = 'https://openexchangerates.org/api/latest.json'

    # This method returns the exchange rate, the rate at which the smallest unit of one currency (the base currency)
    #   will be exchanged for another currency (the target currency), from Open Exchange Rate's API.
    #   This method is called in the OmniExchange.exchange_currency method.
    #
    # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
    # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
    # @ return [BigDecimal] an exchange rate is returned as a BigDecimal for precise calculation since this exchange
    #   rate will be used to calculate an convert an exchange of currencies. However, an exception will be raised
    #   if there is a timeout while connecting to xe.com or a timeout while reading Open Exchange Rate's API.
    def self.get_exchange_rate(base_currency:, target_currency:)
      config = OmniExchange.configuration.provider_config[:open_exchange_rates]
      app_id = config[:app_id]

      api = Faraday.new(OmniExchange::OpenExchangeRates::ENDPOINT_URL)

      begin
        response = api.get do |req|
          req.url "?app_id=#{app_id}&base=#{base_currency}"
          req.options.timeout = config[:read_timeout] || OmniExchange::Configuration::DEFAULT_READ_TIMEOUT
          req.options.open_timeout = config[:connect_timeout] || OmniExchange::Configuration::DEFAULT_CONNECTION_TIMEOUT
        end
      rescue *EXCEPTIONS => e
        raise e.class, 'Open Exchange Rates has timed out.'
      end

      begin
        exchange_rate = JSON.parse(response.body, symbolize_names: true)[:rates][target_currency.to_sym].to_d
      rescue JSON::ParserError => e
        raise e.class, 'JSON::ParserError in OmniExchange::OpenExchangeRates'
      end

      currency_unit = get_currency_unit(base_currency).to_d

      (exchange_rate * currency_unit).to_d
    end

    # when this file is required at the top of lib/omni_exchange.rb, this method call is run and allows
    #   OmniExchange::OpenExchangeRates to be registered in @providers.
    OmniExchange::Provider.register_provider(:open_exchange_rates, self)
  end
end
