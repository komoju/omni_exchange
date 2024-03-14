# frozen_string_literal: true

require 'omni_exchange'

module OmniExchange
  class Xe < Provider
    ENDPOINT_URL = 'https://xecdapi.xe.com/'

    class << self
      # This method returns the exchange rate, the rate at which the smallest unit of one currency (the base currency)
      #   will be exchanged for another currency (the target currency), from xe.com's API.
      #   This method is called in the OmniExchange.exchange_currency method.
      #
      # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
      # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
      # @ return [BigDecimal] an exchange rate is returned as a BigDecimal for precise calculation since this exchange
      #   rate will be used to calculate an convert an exchange of currencies. However, an exception will be raised
      #   if there is a timeout while connecting to xe.com or a timeout while reading xe.com's API.
      def get_exchange_rate(base_currency:, target_currency:)
        body = api_get do |req|
          req.url 'v1/convert_from.json'

          req.params['from'] = base_currency
          req.params['to'] = target_currency
          req.params['amount'] = 1
        end

        body[:to][0][:mid].to_d
      end

      # This method returns the historic exchange rate for multiple currencies for a given date.
      #
      # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from.
      #                                ie. "USD", "JPY"
      # @param target_currencies: [Array] an array of ISO Currency Codes of the currencies that you're
      #                                   exchanging to. ie. ["EUR", "KRW"]
      # @param date: [Date] the date for which you want the historic exchange rate.
      def get_historic_rate(base_currency:, target_currencies:, date:)
        body = api_get do |req|
          req.url 'v1/historic_rate.json'

          req.params['from'] = base_currency
          req.params['to'] = target_currencies.join(',')
          req.params['amount'] = 1
          req.params['date'] = date.strftime('%Y-%m-%d')
        end

        rates = {}
        body[:to].each do |rate|
          rates[rate[:quotecurrency]] = rate[:mid].to_d
        end

        rates
      end

      private

      def api_get(&blk)
        response = api.get do |req|
          blk.call(req)

          req.options.timeout = config[:read_timeout] ||
                                OmniExchange::Configuration::DEFAULT_READ_TIMEOUT
          req.options.open_timeout = config[:connect_timeout] ||
                                     OmniExchange::Configuration::DEFAULT_CONNECTION_TIMEOUT
        end

        body = JSON.parse(response.body, symbolize_names: true)

        raise OmniExchange::XeMonthlyLimit, 'Xe.com monthly limit has been exceeded' if body[:code] == 3

        body
      end

      def api
        api_id = config[:api_id]
        api_key = config[:api_key]

        Faraday.new(OmniExchange::Xe::ENDPOINT_URL) do |f|
          f.set_basic_auth api_id, api_key
          f.adapter :net_http
        end
      end

      def config
        OmniExchange.configuration.provider_config[:xe]
      end
    end

    # when this file is required at the top of lib/omni_exchange.rb, this method call is run and allows
    #   OmniExchange::Xe to be registered in @providers.
    OmniExchange::Provider.register_provider(:xe, self)
  end
end
