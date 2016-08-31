namespace :glimr_api_client do
  desc 'Copy the shared examples for glimr rspec testing'
  task :install_shared_examples
    source = File.join(
      Gem.loaded_specs['glimr-api-client'].full_gem_path,
      'spec',
      'support',
      'shared_examples_for_glimr.rb'
    )
    target = File.join(Rails.root, 'spec', 'support', 'shared_examples_for_glimr.rb')
    FileUtils.cp_r source, target
end
