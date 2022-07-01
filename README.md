# OmniExchange

OmniExchange converts currencies using up-to-the-minute foreign exchange rates.

OmniExchange also supports fail-over logic and handles timeouts. In other words, if currency conversion isn't possible because an API data source cannot provide an exchange rate, OR if that data source times out, OmniExchange will retrieve exchange rate data seamlessly from another API data source.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omni_exchange'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install omni_exchange

## Usage

#### **Step 1) Create an XE and/or Open Exchange Rates Account**

OmniExchange currently supports the ability to fetch foreign exchange rates data from XE and Open Exchange Rates. So, in order to use OmniExchange, you will need to sign up for either [XE](https://www.xe.com/xecurrencydata/), [Open Exchange Rates](https://openexchangerates.org/), or both.

#### **Step 2) Configure**

```ruby
OmniExchange.configure do |config|
  config.provider_config = {
    xe: {
      api_id: 'your XE api id here as a string', # REQUIRED TO USE XE
      api_key: 'your XE api id here as a string', # REQUIRED TO USE XE
      # read_timeout: 5, # OPTIONAL; by default, OmniExchange will try to read API data for 5 seconds before timing out
      # connect_timeout: 2 # OPTIONAL; by default, OmniExchange will try to connect to XE for 2 seconds before timing out
    },
    open_exchange_rates: {
      app_id: 'your Open Exchange Rates app id here as a string' # REQUIRED TO USE OPEN EXCHANGE RATES
      # read_timeout: 5, # OPTIONAL; by default, OmniExchange will try to read API data for 5 seconds before timing out
      # connect_timeout: 2 # OPTIONAL; by default, OmniExchange will try to connect to Open Exchange Rates for 2 seconds before timing out
    }
  }
end
```

#### **Step 3) Convert Currency and/or Get An Exchange Rate**

To convert currency and/or get an exchange rate, all you have to do is call `OmniExchange.get_fx_data()`. This method requires you to pass the following four named parameters:
1. amount: (Integer) the amount of the currency you want to convert. NOTE: OmniExchange will read this amount as being the smallest unit of a currency. In other words, if you pass `10` as the amount for USD, OmniExchange will read this as 10 cents, not 10 dollars.
2. base_currency: (String) the ISO Currency Code of the currency that you're exchanging from. ie. 'USD', 'JPY'
3. target_currency: (String) the ISO Currency Code of the currency that you're exchanging to. ie. 'EUR', 'KRW'
4. providers: (Array of Symbols) the keys of the API providers that you want data from in order of preference. ie. [:xe, :open_exchange_rates]

What you get back is a hash containing:
1. converted_amount: (BigDecimal) the amount of money exchanged from the base currency to the target currency
2. exchange_rate: (BigDecimal) the rate used to calculate the converted_amount
3. provider_class: (Class) the name of the provider class that supplied the exchange_rate (ie. OmniExchange::OpenExhangeRates)

[For the sake of precise calculation](https://www.bigbinary.com/blog/handling-money-in-ruby), converted_amount and exchange_rate are BigDecimal. Simply call `.to_f` to the results if you'd like to see a number that is easier to read.


Here is an example. Lets say I want to convert $1.00 US Dollar to Japanese Yen, and I want it converted using exchange rate data from Open Exchange Rates. If Open Exchange Rates fails, I'd like OmniExchange to try to use exchange rate data from Xe as a fallback.

```ruby
USD_to_JPY = OmniExchange.get_fx_data(amount: 100, base_currency: 'USD', target_currency: 'JPY', providers: [:open_exchange_rates, :xe])

puts USD_to_JPY # => { :converted_amount=>0.13566633333e3, :exchange_rate=>0.13566633333e1, :provider_class=>OmniExchange::OpenExchangeRates }

puts USD_to_JPY[:converted_amount] # => 0.13566633333e3
puts USD_to_JPY[:converted_amount].to_f # => 135.66633333

puts USD_to_JPY[:exchange_rate] # => 0.13566633333e1
puts USD_to_JPY[:exchange_rate].to_f # => 1.3566633333

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and issues are welcome on GitHub at https://github.com/degica/omni_exchange. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/degica/omni_exchange/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OmniExchange project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/degica/omni_exchange/blob/master/CODE_OF_CONDUCT.md).
