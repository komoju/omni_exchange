# frozen_string_literal: true

module OmniExchange
  # A custom error for an unknown or invalid currency
  class UnknownCurrency < StandardError
  end

  # A custom error for failure to get data from a provider
  class HttpError < StandardError
  end

  # A custom error for exceeding the monthly request limit for xe.com
  class XeMonthlyLimit < StandardError
  end
end
