# Rails.application.config.session_store :cookie_store, key: '_aviary_session', domain: :all, tld_length: 2

Rails.application.config.session_store :cache_store, key: ENV['SESSION_KEY']  || '_aviary_key' , domain: :all, tld_length: 2



# :redis_store, {
#   servers: [
#     { host: ENV['REDIS_SERVER'] || 'localhost', port: 6379, db: 0 },
#   ],
#   key: ENV['SESSION_KEY'] || '_aviary_key', domain: :all, tld_length: 2
# }
