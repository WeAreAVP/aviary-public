source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'nokogiri', '>= 1.8.5'
group :development, :test do
  gem 'sqlite3'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-rails'
  gem 'solr_wrapper', '>= 0.3'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'letter_opener'
  gem 'pry'
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'awesome_print', require: 'ap'
  gem 'rubocop', '= 0.49.1'
  # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
  gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
  gem 'rails-erd'
  gem 'xray-rails'
  gem 'bullet'
end

group :test do
  gem 'rspec', '~> 3.7'
  gem 'rspec-rails', '~> 3.7'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'shoulda-matchers'
  # Use Puma as the app server
  gem "puma", ">= 3.12.6"
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper' # <- New!
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rails-controller-testing'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'with_model'
end

gem 'mysql2'
gem "devise", ">= 4.7.1"
gem 'devise_invitable', '~> 1.7.0'
gem 'jquery-rails', '~> 4.3', '>= 4.3.1'
gem 'dotenv-rails'

# capistrano for deployment
gem 'capistrano', '~> 3.10', require: false
gem 'capistrano-rails', '~> 1.3', require: false
gem 'capistrano-passenger', '~> 0.2.0', require: false
gem 'capistrano-rbenv', '~> 2.1', require: false
gem 'capistrano3-puma', '~> 3.1', '>= 3.1.1'
# Datatables https://www.driftingruby.com/episodes/datatables
gem 'rails-assets-jquery', source: 'https://rails-assets.org'
gem 'kaminari'

# Draper adds an object-oriented layer of presentation logic to your Rails application.
gem 'draper'

gem "simple_form", ">= 5.0.0"
gem 'country_select'
gem 'city-state'

# file attachment library
gem 'paperclip', '~> 6.0.0'
gem 'paperclip-compression'
gem 'aws-sdk-s3'

# Rails JQuery
gem 'jquery-ui-rails'
gem 'autocomplete_rails'
gem 'cocoon'
gem 'jquery-fileupload-rails'

# Attr Encrypted
gem 'attr_encrypted', '~> 3.0.0'
gem 'bootstrap-tagsinput-rails'
gem 'bootstrap-datepicker-rails'
gem "rack-cors", ">= 1.0.4"
gem 'best_in_place'
gem 'cancancan'
gem 'rack', '>= 2.0.6'
gem 'loofah', '>= 2.2.3'

# Color Picker https://labs.abeautifulsite.net/jquery-minicolors/
gem 'jquery-minicolors-rails'

gem 'client_side_validations'

# Code Coverage and publish on Codacy Gem
gem 'codacy-coverage', :require => false
gem 'simplecov', require: false

# Cron
gem 'sidekiq'

gem 'redis-rails'
# Process WebVTT file
gem 'webvtt-ruby'

# Getting info of a video
gem 'soundcloud'
gem 'streamio-ffmpeg'
gem 'video_info'

# run the business logic in a transaction
gem 'dry-transaction'

gem 'blacklight_advanced_search'
gem 'blacklight_range_limit'
gem 'sunspot_rails'
gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development. Please find a section below explaining other options for running Solr in production '
gem 'rsolr', '>= 1.0'
gem 'jquery-datatables'

gem 'momentjs-rails'
gem 'bootstrap-daterangepicker-rails'

gem 'bootsnap', require: false

gem 'noid-rails'
gem 'clipboard-rails'


# Analystics
gem 'ahoy_matey'

gem 'tinymce-rails'
gem 'open_uri_redirections'


gem 'iso-639'

gem 'curb'
gem 'countries'

gem 'geoip'
gem 'ip2location_ruby'
gem 'maxminddb'
gem 'breadcrumbs_on_rails'
gem 'rack-attack'

gem 'activerecord_json_validator'


gem 'treehash'
# Airbrake lib/platform for Error/Performance Monitoring and Reporting
gem 'airbrake', '>= 10.0.3'

# Caching helper .new(Rails.application.secrets.secret_key_base[0..31], Rails.application.secrets.secret_key_base)gems
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'


# SEO GEM
gem 'sitemap_generator'
gem 'meta-tags'


# React Integration
gem 'react_on_rails'
gem 'webpacker'
gem 'mini_racer', platforms: :ruby

gem "rubyzip", ">= 1.3.0"
