# Rails.application.config.session_store :cookie_store, key: '_aviary_session', domain: :all, tld_length: 2

Rails.application.config.session_store :redis_store, {
  servers: [
    { host: ENV['REDIS_SERVER'] || 'localhost', port: 6379, db: 0 },
  ],
  key: '_aviary_key',domain: :all, tld_length: 2
}
