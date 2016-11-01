$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require 'glimr_api_client/version'

Gem::Specification.new do |spec|
  spec.name = 'glimr-api-client'
  spec.version = GlimrApiClient::VERSION
  spec.authors = ['Todd Tyree']
  spec.email = ['todd.tyree@digital.justice.gov.uk']

  spec.summary = 'Easy integration with the glimr case management system'
  spec.homepage = 'https://github.com/ministryofjustice/glimr-api-client'
  spec.licenses = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'capybara', '~> 2.7'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.2'
  spec.add_development_dependency 'fuubar', '~> 2.0'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
  spec.add_development_dependency 'rails', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.41'
  spec.add_development_dependency 'sqlite3', '~> 1.3'

  spec.add_dependency 'excon', '~> 0.51'
end
