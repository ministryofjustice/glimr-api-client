$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require 'glimr_api_client/version'

Gem::Specification.new do |spec|
  spec.name = 'glimr-api-client'
  spec.version = GlimrApiClient::VERSION
  spec.authors = ['Todd Tyree']
  spec.email = ['todd.tyree@digital.justice.gov.uk']

  spec.summary = 'Easy integration with the glimr case management system'
  spec.homepage = 'https://github.com/ministryofjustice/glimr-api-client'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'launchy'
  spec.add_development_dependency 'mutant-rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails', '~> 5.0.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'

  spec.add_dependency 'excon'
end
