source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '>= 6.1.6.1'
group :development, :production do
  # Use mysql as the database for Active Record
  gem 'mysql2', '~> 0.5'
end
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets

gem 'sass-rails', '>= 6'
gem 'sprockets', '~> 4'
gem 'sprockets-rails', :require => 'sprockets/railtie'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
#gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
gem 'hiredis'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry'
  gem 'pry-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'letter_opener'

  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails-erd'
  # gem 'xray-rails'

  gem 'pry-stack_explorer'

  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-ast', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rake', require: false
end

gem 'license_finder'
group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
  # sqlite db
  gem 'sqlite3'

  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'factory_bot_rails'

  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'with_model'
  gem 'simplecov'
  gem 'codacy-coverage'
  # Adds support for Capybara system testing and selenium driver

  gem 'chromedriver-helper' # <- New!
  gem 'capybara-screenshot'
  gem 'shoulda-matchers'
end

gem 'bigdecimal'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Add additional after this line those are needed for this project

# capistrano for deployment
gem 'capistrano', require: false
gem 'capistrano-rails', require: false
# gem 'capistrano-passenger', '~> 0.2.0', require: false
gem 'capistrano-rbenv', require: false
gem 'capistrano3-puma', require: false
gem 'ed25519', '~> 1.2'
gem 'bcrypt_pbkdf', '~> 1'

gem "aws-sdk-s3"

gem 'mini_magick'
gem 'nokogiri'

gem "devise"
gem 'devise_invitable'
#
gem "simple_form", ">= 5.0.0"
gem 'country_select'
gem 'city-state'
#
# # Draper adds an object-oriented layer of presentation logic to your Rails application.
gem 'draper'
#
# # Datatables https://www.driftingruby.com/episodes/datatables
gem 'rails-assets-jquery', source: 'https://rails-assets.org'
gem 'kaminari'
#
#
# # Rails JQuery
gem 'jquery-ui-rails'
gem 'rails-autocomplete'
gem 'cocoon'
gem 'jquery-fileupload-rails'
#
gem 'attr_encrypted', '~> 3.0.0'
gem 'bootstrap-tagsinput-rails'
gem 'bootstrap-datepicker-rails'
gem "rack-cors", ">= 1.0.4"
gem "best_in_place", git: "https://github.com/mmotherwell/best_in_place"
gem 'cancancan'
#
# # Color Picker https://labs.abeautifulsite.net/jquery-minicolors/
gem 'jquery-minicolors-rails'
#
gem 'client_side_validations'
#
gem 'sidekiq'
#

#
# # Getting info of a video
gem 'soundcloud'
gem 'streamio-ffmpeg'
gem 'video_info'
#
# # run the business logic in a transaction
gem 'dry-transaction'
#
gem 'jquery-datatables'
#
gem 'momentjs-rails'
gem 'bootstrap-daterangepicker-rails'
#
gem 'stripe'
gem 'stripe_event'
gem 'noid-rails'
gem 'clipboard-rails'
#
#
# # Analystics
gem 'ahoy_matey'
#
gem 'tinymce-rails'
gem 'open_uri_redirections'
#
gem 'ibm_watson'
gem 'taxjar-ruby', require: 'taxjar'
#
gem 'iso-639'
#
gem 'curb'
gem 'countries'
#
gem 'geoip'
gem 'ip2location_ruby'
gem 'maxminddb'
gem 'breadcrumbs_on_rails'
gem 'rack-attack'
gem 'simple_uuid'
gem 'omniauth-multi-provider-saml'
gem "omniauth-rails_csrf_protection"
gem 'activerecord_json_validator'
gem 'rails-letsencrypt'
gem 'aws-sdk-glacier', '~> 1.0.0.rc1'
gem 'treehash'

# # DNS verification
# gem 'dnsruby'
# # Nginx conf generator
gem 'nginx-conf'
#
#
# # Caching helper .new(Rails.application.secrets.secret_key_base[0..31], Rails.application.secrets.secret_key_base)gems
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'fog-aws'
#
# # SEO GEM
gem 'sitemap_generator'
gem 'meta-tags'
#
#
gem "rubyzip", ">= 1.3.0"
gem 'sanitize'
#
gem 'aws-sdk-elastictranscoder', '~> 1.0.0.rc1'
#
gem 'recaptcha'
gem 'invisible_captcha'
#
#
# # API
gem 'devise_token_auth'
gem "paranoia", "~> 2.2"
gem 'rails_same_site_cookie'
#
gem 'docx'
gem 'rest-client'
#
gem 'remove_emoji'
#
gem 'htmlentities'
gem 'yomu'
gem 'sidekiq-limit_fetch'
#
gem 'rqrcode'
#
gem 'pry-remote'
#
gem 'turnout'
#
gem 'simple_hubspot'
gem 'social-share-button'
#
gem 'down', require: false
gem 'bootstrap_tokenfield_rails'
gem 'jquery_mask_rails', '~> 0.1.0'
#
gem 'browser'
gem 'wkhtmltopdf-binary'
gem 'wicked_pdf'
gem 'net-sftp'
#
gem 'blacklight_advanced_search'
gem 'blacklight_range_limit'
gem 'sunspot_rails'
gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development. Please find a section below explaining other options for running Solr in production '

gem 'kt-paperclip'
gem 'paperclip-compression', git: 'https://github.com/smntb/paperclip-compression'

gem 'dotenv-rails'
gem 'jquery-rails'

gem 'net-smtp', require: false

gem 'rsolr', '>= 1.0', '< 3'
gem 'net-pop', require: false
gem 'net-imap', require: false
# gem 'bigdecimal', '1.4.2'
group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

# # Process WebVTT file
gem 'webvtt-ruby', git: 'https://github.com/smntb/webvtt-ruby'
