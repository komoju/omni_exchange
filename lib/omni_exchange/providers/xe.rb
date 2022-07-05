# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
require 'omni_exchange'

module OmniExchange
  class Xe < Provider
    ENDPOINT_URL = 'https://xecdapi.xe.com/'

    # This method returns the exchange rate, the rate at which the smallest unit of one currency (the base currency)
    #   will be exchanged for another currency (the target currency), from xe.com's API.
    #   This method is called in the OmniExchange.exchange_currency method.
    #
    # @param base_currency: [String] the ISO Currency Code of the currency that you're exchanging from. ie. "USD", "JPY"
    # @param target_currency: [String] the ISO Currency Code of the currency that you're exchanging to. ie. "EUR", "KRW"
    # @ return [BigDecimal] an exchange rate is returned as a BigDecimal for precise calculation since this exchange
    #   rate will be used to calculate an convert an exchange of currencies. However, an exception will be raised
    #   if there is a timeout while connecting to xe.com or a timeout while reading xe.com's API.
    def self.get_exchange_rate(base_currency:, target_currency:)
      config = OmniExchange.configuration.provider_config[:xe]
      api_id = config[:api_id]
      api_key = config[:api_key]
      currency_unit = get_currency_unit(base_currency)

      api = Faraday.new(OmniExchange::Xe::ENDPOINT_URL) do |f|
        f.request :basic_auth, api_id, api_key
        f.adapter :net_http
      end

      begin
        response = api.get do |req|
          req.url "v1/convert_from.json/?from=#{base_currency}&to=#{target_currency}&amount=#{currency_unit}"
          req.options.timeout = config[:read_timeout] || OmniExchange::Configuration::DEFAULT_READ_TIMEOUT
          req.options.open_timeout = config[:connect_timeout] || OmniExchange::Configuration::DEFAULT_CONNECTION_TIMEOUT
        end
      rescue Faraday::Error, Faraday::ConnectionFailed => e
        raise e.class, 'xe.com has timed out.'
      end

      body = JSON.parse(response.body, symbolize_names: true)

      raise OmniExchange::XeMonthlyLimit, 'Xe.com monthly limit has been exceeded' if body[:code] == 3

      body[:to][0][:mid].to_d
    end

    # when this file is required at the top of lib/omni_exchange.rb, this method call is run and allows
    #   OmniExchange::Xe to be registered in @providers.
    OmniExchange::Provider.register_provider(:xe, self)
  end
end
# rubocop:enable Metrics/AbcSize
