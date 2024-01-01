#!/bin/sh

# entrypoint.sh
# Start the worker
bundle exec sidekiq &

# Start cron jobs
echo "*/5 * * * * /bin/bash -l -c 'cd /app && RAILS_ENV=production bundle exec rake aviary:unlock_transcript --silent'" | crontab -
echo "0 0 1 * * /bin/bash -l -c 'cd /app && RAILS_ENV=production bundle exec rake aviary:organization_storage_cost --silent'" | crontab -

# Start the cron service
cron -f
