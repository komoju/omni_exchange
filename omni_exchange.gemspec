# frozen_string_literal: true

require_relative 'lib/omni_exchange/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'omni_exchange'
  spec.version       = OmniExchange::VERSION
  spec.authors       = ['Yun Chung']
  spec.email         = ['yunseok_chung@degica.com']

  spec.summary       = 'OmniExchange converts currencies using up-to-the-minute foreign exchange rates.'
  spec.description   = 'OmniExchange converts currencies using up-to-the-minute foreign exchange rates.'
  spec.homepage      = 'https://komoju.com'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = 'https://komoju.com'
  spec.metadata['source_code_uri'] = 'https://github.com/komoju/omni_exchange'
  spec.metadata['changelog_uri'] = 'https://github.com/komoju/omni_exchange'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'base64', '~> 0.2.0'
  spec.add_dependency 'bigdecimal', '~> 3'
  spec.add_dependency 'faraday', '~> 2'
  spec.add_dependency 'money', '~> 6.13.1'
  spec.add_dependency 'racc', '~> 1.4'
  spec.add_dependency 'stringio', '~> 3.1.2'

  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.80'
  spec.add_development_dependency 'vcr'
end
# rubocop:enable Metrics/BlockLength
