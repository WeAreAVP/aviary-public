require_relative 'boot'
require 'rails/all'
require 'json'
require 'dotenv/load'

Bundler.require(*Rails.groups)
Dotenv::Railtie.load

module Aviary
  # Application Class
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.encoding = 'utf-8'
    config.load_defaults 5.1
    config.assets.paths << Rails.root.join('vendor', 'app', 'assets', 'fonts')
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get options]
      end
    end
    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(',')
    }

    config.autoload_paths += Dir["#{config.root}/lib/**/", "#{config.root}/app/services/**/"]
    config.active_job.queue_adapter = :sidekiq
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'America/Los_Angeles' # Your local time zone
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
  end
end
