# configuration to deploy the application on the staging server
set :stage, :production
set :branch, 'main'

set :server_name, 'public.aviaryplatform.com'
set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"

server '3.134.217.160', user: 'deploy', roles: %w{web app db}, port: 22

set :deploy_to, -> { '/home/deploy/aviary' }
set :rails_env, :production

set :enable_ssl, true
