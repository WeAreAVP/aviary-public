require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aviary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.encoding = 'utf-8'
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.autoloader = :classic
    # config.autoload_paths << config.root.join('lib')
    # config.autoload_paths << config.root.join('services')
    # onfig.assets.paths << Rails.root.join('vendor', 'app', 'assets', 'fonts')
    # config.middleware.insert_before 0, Rack::Cors do
    #   allow do
    #     origins '*'
    #     resource '*', headers: :any,
    #              methods: %i[get post put patch delete options head],
    #              expose: %w[access-token expiry token-type uid client organization-id]
    #   end
    # end
    # config.action_dispatch.default_headers = {
    #   'Access-Control-Allow-Origin' => '*',
    #   'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(',')
    # }
    config.autoload_paths += Dir["#{config.root}/lib/**/", "#{config.root}/app/services/**/", "#{config.root}/app/services/aviary/ssl_certificate_manager/**",
                                 "#{config.root}/app/services/aviary/field_management/base_field_manager.rb", "#{config.root}/app/services/aviary/field_management/**",
                                 ]
    config.active_job.queue_adapter = :sidekiq
    config.time_zone = 'America/New_York' # Your local time zone
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
  end
end
