def set_subdomain
  default_url_options[:host] = ENV['APP_HOST']
end
