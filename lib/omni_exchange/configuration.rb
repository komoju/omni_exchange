# frozen_string_literal: true

module OmniExchange
  class Configuration
    attr_accessor :provider_config

    # unless a read_timeout has been set in :provider_config, a provider
    # will attempt to read an API response for the amount of seconds
    # set as the DEFAULT_READ_TIMEOUT before timing out
    DEFAULT_READ_TIMEOUT = 5

    # unless a connect_timeout has been set in :provider_config, a provider
    # will attempt to connect to an API for the amount of seconds
    # set as the DEFAULT_CONNECTION_TIMEOUT before timing out
    DEFAULT_CONNECTION_TIMEOUT = 2

    # an new Configuration instance is instantiated when
    # OmniExchange.configure is called (see lib/omni_exchange.rb)
    def initialize
      @provider_config = nil
    end
  end
end
