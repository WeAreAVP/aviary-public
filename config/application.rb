require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aviary
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    # config.active_support.cache_format_version = 6.1
    config.encoding = 'utf-8'
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
    # config.add_autoload_paths_to_load_path = true

    config.autoloader = :classic
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config.autoload_paths += Dir["#{config.root}/app/services/**/", "#{config.root}/app/services/aviary/ssl_certificate_manager/**/",
    #                               "#{config.root}/app/services/aviary/field_management/**/" ]
    # config.autoload_paths << "#{Rails.root}/app/services"
    # config.eager_load_paths << "#{Rails.root}/app/services"
    config.active_job.queue_adapter = :sidekiq
    config.time_zone = 'America/New_York' # Your local time zone
    # config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
    config.active_record.yaml_column_permitted_classes = [Symbol, Hash, Array, ActiveSupport::HashWithIndifferentAccess]
    config.active_record.encryption.primary_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY', nil)
    config.active_record.encryption.deterministic_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY', nil)
    config.active_record.encryption.key_derivation_salt = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT', nil)
  end
end
