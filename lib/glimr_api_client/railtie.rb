require 'glimr_api_client'
require 'rails'
module GlimrApiClient
  class Railtie < Rails::Railtie
    railtie_name :glimr_api_client

    rake_tasks do
      load 'tasks/spec_setup.rake'
    end
  end
end
