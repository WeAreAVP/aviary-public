# configuration to deploy the application on the staging server
set :stage, :production
set :branch, 'AVIARY-3524_AVIARY-3525_AVIARY-3526_AVIARY-3520_AVIARY-3521_AVIARY-3510'

set :server_name, 'public.aviaryplatform.com'
set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"

server '3.134.217.160', user: 'deploy', roles: %w{web app db}, port: 22

set :deploy_to, -> { '/home/deploy/aviary' }
set :rails_env, :production

set :enable_ssl, true
