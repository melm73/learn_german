require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module LearnGerman
  class Application < Rails::Application
    config.load_defaults 6.0

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.helper false
      g.stylesheets false
      g.helper_specs false
    end
  end
end
