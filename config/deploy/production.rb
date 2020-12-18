# configuration to deploy the application on the staging server
set :stage, :production
set :branch, 'AVIARY-2186_time_auto_play_url'

set :server_name, 'public.aviaryplatform.com'
set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"

server 'public.aviaryplatform.com', user: 'deploy', roles: %w{web app db}, port: 5222

set :deploy_to, -> { '/home/deploy/aviary' }
set :rails_env, :production

set :enable_ssl, false
