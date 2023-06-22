#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access

redis_conn = { url: "redis://#{config[:host]}:#{config[:port]}/" }

Sidekiq.configure_server do |s|
  s.redis = redis_conn
end

Sidekiq.configure_client do |s|
  s.redis = redis_conn
end

Sidekiq.strict_args!(false)
