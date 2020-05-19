Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = false

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Attempt to read encrypted secrets from `config/secrets.yml.enc`.
  # Requires an encryption key in `ENV["RAILS_MASTER_KEY"]` or
  # `config/secrets.yml.key`.
  config.read_encrypted_secrets = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]
  config.action_cable.allowed_request_origins = [%r{http://*}, %r{https://*}]
  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = %i[request_id remote_ip]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  config.cache_store = :redis_store, "redis://#{ENV['REDIS_SERVER']}:6379/1", { expires_in: 24.hours }
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
  }
  config.assets.js_compressor = Uglifier.new(harmony: true, output: {
                                               comments: :none,
                                               bracketize: false,
                                               preserve_line: false,
                                               beautify: false,
                                               indent_level: 0,
                                               keep_quoted_props: 0
                                             })
  config.assets.css_compressor = :sass
  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "testapp_#{Rails.env}"
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: ENV['APP_HOST'] }
  config.action_mailer.asset_host = "https://#{ENV['APP_HOST']}"
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: ENV['SMTP_ADDRESS'],
                                         port: 587,
                                         domain: ENV['SMTP_DOMAIN'],
                                         user_name: ENV['SMTP_USERNAME'],
                                         password: ENV['SMTP_PASSWORD'],
                                         authentication: :login,
                                         enable_starttls_auto: true }
  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  config.action_dispatch.tld_length = ENV['TLD_LENGTH'].to_i || 2

  config.paperclip_defaults = { storage: :s3,
                                s3_protocol: :https,
                                url: ':s3_alias_url',
                                s3_host_alias: ENV['S3_HOST_CDN'],
                                path: '/:class/:attachment/:id_partition/:style/:filename',
                                s3_credentials: { bucket: ENV['S3_BUCKET_NAME'],
                                                  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                                  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
                                                  s3_region: ENV['S3_REGION'],
                                                  s3_host_name: ENV['S3_HOST_NAME'] } }
end
