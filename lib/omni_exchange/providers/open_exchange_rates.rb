# frozen_string_literal: true

require 'omni_exchange'

module OmniExchange
  class OpenExchangeRates < Provider
    ENDPOINT_URL = 'https://openexchangerates.org/api/'

    class << self
      # This method returns the exchange rate, the rate at which the smallest unit of one currency (the base currency)
      #   will be exchanged for another currency (the target currency), from Open Exchange Rate's API.
      #   This method is called in the OmniExchange.exchange_currency method.
      #
      # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
      # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
      # @ return [BigDecimal] an exchange rate is returned as a BigDecimal for precise calculation since this exchange
      #   rate will be used to calculate an convert an exchange of currencies. However, an exception will be raised
      #   if there is a timeout while connecting to xe.com or a timeout while reading Open Exchange Rate's API.
      def get_exchange_rate(base_currency:, target_currency:)
        body = api_get do |req|
          req.url 'latest.json'
          req.params['base'] = base_currency
          req.params['symbols'] = target_currency
        end

        exchange_rate = body['rates'][target_currency].to_d
        currency_unit = get_currency_unit(base_currency).to_d

        (exchange_rate * currency_unit).to_d
      end

      def get_historic_rate(base_currency:, target_currencies:, date:)
        body = api_get do |req|
          req.url "historical/#{date.strftime('%Y-%m-%d')}.json"

          req.params['base'] = base_currency
          req.params['symbols'] = target_currencies.join(',')
        end

        currency_unit = get_currency_unit(base_currency).to_d
        body['rates'].map do |currency, rate|
          [currency, (rate * currency_unit).to_d]
        end.to_h
      end

      private

      def api_get(&blk)
        api = Faraday.new(OmniExchange::OpenExchangeRates::ENDPOINT_URL)

        response = api.get do |req|
          blk.call(req)

          req.params['app_id'] = config[:app_id]

          req.options.timeout = config[:read_timeout] ||
                                OmniExchange::Configuration::DEFAULT_READ_TIMEOUT
          req.options.open_timeout = config[:connect_timeout] ||
                                     OmniExchange::Configuration::DEFAULT_CONNECTION_TIMEOUT
        end

        JSON.parse(response.body)
      end

      def config
        OmniExchange.configuration.provider_config[:open_exchange_rates]
      end
    end

    # when this file is required at the top of lib/omni_exchange.rb, this method call is run and allows
    #   OmniExchange::OpenExchangeRates to be registered in @providers.
    OmniExchange::Provider.register_provider(:open_exchange_rates, self)
  end
end
