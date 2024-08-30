#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

require 'capistrano/rbenv'
set :rbenv_type, :user
set :rbenv_ruby, '3.3.4'

require 'capistrano/scm/git'

require 'capistrano/puma'
require 'capistrano/puma/nginx'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Nginx
install_plugin Capistrano::Puma::Systemd

require 'capistrano/rails'

require 'capistrano/rails/migrations'

require 'capistrano/sitemap_generator'

install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
