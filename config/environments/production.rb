require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  config.action_cable.allowed_request_origins = [%r{http://*}, %r{https://*}]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT by default
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.logger = ActiveSupport::Logger.new($stdout)
                                         .tap { |logger| logger.formatter = Logger::Formatter.new }
                                         .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  end

  # Prepend all log lines with the following tags.
  config.log_tags = %i[request_id remote_ip]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'warn')

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, { url: ENV['ACTION_CABLE_REDIS'] || 'localhost' }
  # config.session_store :cache_store, key: ENV['SESSION_KEY'] || '_aviary_key', domain: :all
  config.session_store :cache_store, key: ENV['SESSION_KEY'] || '_aviary_key',
                                     domain: %w(.lvh.me .localhost .aviaryplatform.com .www.kznarchives.gov.za .archive.culturalmediaarchive.org .avcollections.library.yale.edu .aviary.ecds.emory.edu .aviary.libraries.emory.edu .aviary.library.vanderbilt.edu .www.beneathourskin.org .hlavmass.lib.harvard.edu .hlavsandbox.lib.harvard.edu .oralhistory.iu.edu .qatartalkingarchives.org .streaming.peabody.jhu.edu .video.eastview.com)

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "aviary_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: ENV.fetch('APP_HOST', nil), protocol: 'https' }
  config.action_mailer.asset_host = "https://#{ENV.fetch('APP_HOST', nil)}"
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: ENV.fetch('SMTP_ADDRESS', nil),
                                         port: 587,
                                         domain: ENV.fetch('SMTP_DOMAIN', nil),
                                         user_name: ENV.fetch('SMTP_USERNAME', nil),
                                         password: ENV.fetch('SMTP_PASSWORD', nil),
                                         authentication: :login,
                                         enable_starttls_auto: true }
  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.report_deprecations = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  config.paperclip_defaults = { storage: :s3,
                                s3_protocol: :https,
                                url: ':s3_alias_url',
                                s3_host_alias: ENV.fetch('S3_HOST_CDN', nil),
                                path: '/:class/:attachment/:id_partition/:style/:filename',
                                s3_credentials: { bucket: ENV.fetch('S3_BUCKET_NAME', nil),
                                                  access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
                                                  secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
                                                  s3_region: ENV.fetch('S3_REGION', nil),
                                                  s3_host_name: ENV.fetch('S3_HOST_NAME', nil) } }
  config.action_dispatch.tld_length = ENV['TLD_LENGTH'].to_i || 2
end
