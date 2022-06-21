# frozen_string_literal: true

module OmniExchange
  class Provider
    # @providers is a hash of registered providers that OmniExchange can request exchange rates data from
    @providers = {}
    @currency_data = nil

    # This method registers providers by adding a provider's name as a key and a provider class as a value to
    #   @providers. This happens automatically on load at the top of the lib/omni_exchange.rb file when each
    #   file in the lib/omni_exchange/providers folder becomes required.
    #
    # @param provider_name [Symbol] the name of the exchange rate API data provider. ie. :xe, :open_exchange_rates
    # @param provider_module [Class] the class of the provider. ie. OmniExchange::Xe, OmniExchange::OpenExchangeRates
    def self.register_provider(provider_name, provider_module)
      @providers[provider_name] = provider_module
    end

    # This method is called in the .exchange_currency method. It returns the provider that is requested if the provider
    #   is registered in the @providers hash. Once loaded, class methods (such as .get_exchange_rate) can be called on
    #   the provider. However, if the provider is unregistered, a LoadError is raised.
    #
    # @param provider_name [Symbol] the name of the exchange rate API provider that is to be loaded. ie. :xe
    # @return [Class] the provider is returned if it has been registered properly in the @providers hash. Otherwise,
    #   a LoadError exception is raised
    def self.load_provider(provider_name)
      provider = @providers[provider_name]
      return provider if provider

      raise(LoadError.new, "#{provider_name} did not load properly as a provider")
    end

    # a method that gives access to the @providers hash and the providers registered in it
    def self.all
      @providers
    end

    # Each provider class should inherit from Provider and have a .get_exchange_rates method. If a provider class
    #   doesn't have a .get_exchange_rates method, the method below will be called and an error will be raised.
    def self.get_exchange_rate
      raise 'method not implemented...'
    end

    # Some currencies, such as the US dollar, have subunits (ie. cents). Therefore, to make sure that currencies are
    #   exchanged accurately, a currency's subunit needs to be taken into account, and that's what this method does.
    #   Subunit data of currencies is stored as @currency_data after being read from the currency_data.json file.
    #
    # @param base_currency [String] the ISO Currency Code of the currency that you're exchanging from. A check is done
    #   on this currency to see if it has subunits (such as the US dollar having cents). ie. "USD", "JPY"
    # @return [Float] the amount an exchange rate should be multiplied by to account for subunits
    def self.get_currency_unit(base_currency)
      return 1.0 / @currency_data[base_currency.downcase]['subunit_to_unit'] if @currency_data

      file = File.read(File.join(File.dirname(__FILE__), './currency_data.json'))
      @currency_data = JSON.parse(file)

      1.0 / @currency_data[base_currency.downcase]['subunit_to_unit']
    end
  end
end
