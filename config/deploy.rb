# config valid for current version and patch releases of Capistrano
# lock '~> 3.11.0'
# Bundler Integration

# Application Settings
set :application, 'aviary'
set :user, 'deploy'

# setup repo details
set :repo_url, 'git@github.com:WeAreAVP/aviary-public.git'

# how many old releases do we want to keep, not much
set :keep_releases, 3

# files we want symlinking to specific entries in shared
set :linked_files, %w{.env}

set :use_sudo, true

# Uses local instead of remote server keys, good for github ssh key deploy.
set :ssh_options, keys: ['config/deploy_id_rsa'] if File.exist?('config/deploy_id_rsa')

namespace :deploy do
  # before :deploy, 'copy:database_file'
  before :deploy, 'copy:env_file'
  after :deploy, 'restart:nginx'
  after :deploy, 'sidekiq:restart'
  before 'deploy:assets:precompile', 'deploy:yarn_install'
  after :deploy, 'copy:create_symbolic_links'
end
