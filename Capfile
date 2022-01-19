#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

if %w[production production_worker development].include?(ARGV[0].to_s)
  require 'capistrano/rbenv'
  set :rbenv_type, :user
  set :rbenv_ruby, '3.1.0'
end

require 'capistrano/scm/git'
if %w[production development].include?(ARGV[0].to_s)
  require 'capistrano/puma'
  require 'capistrano/puma/nginx'
  install_plugin Capistrano::Puma
  install_plugin Capistrano::Puma::Nginx
  install_plugin Capistrano::Puma::Systemd
end
if %w[production production_worker development staging].include?(ARGV[0].to_s)
  require 'capistrano/rails'
  # require 'capistrano/passenger' if ARGV[0].to_s == 'production'
  require 'capistrano/rails/migrations'
end
require 'capistrano/sitemap_generator'

install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
