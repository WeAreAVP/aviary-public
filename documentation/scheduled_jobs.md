### Scheduled/Cron Jobs

* Calculate the organization storage cost

        0 0 1 * *  /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:organization_storage_cost --silent'

* Send the notification to organization after a month if their subscription expired

        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:after_month_notification --silent'

* Delete organization data from the system and wasabi if they cancel the subscription

        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:delete_organization_data --silent'

* Update Pay as you go subscription quality

        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake stripe:update_subscription_quantity --silent'

* Update organization storage used
        
        @hourly /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:organization_utilization --silent'

* Send notification email to take flight subscriptions

        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:takeflight_notification --silent'

* Activate take flight organization to paid if entered their credit card

        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:activate_free_to_paid --silent'

* SEO Sitemap Refresh
        
        @daily /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake sitemap:refresh --silent'

* Unlock the transcript after 24 hours
        
        */5 * * * * /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:unlock_transcript --silent'

* IBM Watson check transcription status and add transcripts on complete

        */5 * * * * /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:watson:check_job --silent'

* AWS Glacier backup of the wasabi data

        */15 * * * * /bin/bash -l -c 'cd /home/deploy/aviary/current && RAILS_ENV=production /home/deploy/.rbenv/shims/bundle exec rake aviary:media_backup --silent'