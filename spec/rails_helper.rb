# frozen_string_literal: true
require 'simplecov'
require 'codacy-coverage'
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') unless Rails.env.test?

require 'rails/all'
require 'rspec/rails'
require 'support/factory_bot'
require 'support/selectize'
require 'support/set_session'
require 'action_view'
require 'spec_helper'
require 'devise'
require 'devise/version'
require 'rspec/matchers'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'database_cleaner'
# require 'shoulda/matchers'
require 'with_model'
# Require support files

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


# See https://github.com/thoughtbot/shoulda-matchers#rspec
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  # This will use the defaults of :js and :server_rendering meta tags
  #ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!


  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation
  
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.include Capybara::DSL
  # config.include WaitForAjax, type: :feature
  config.before :each do
    DatabaseCleaner.clean
    # Note (Mike Coutermarsh): Make browser huge so that no content is hidden during tests
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.include Capybara::DSL
  config.after do
    DatabaseCleaner.clean
  end

  # config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Capybara::RSpecMatchers, type: :input

  # config.include Warden::Test::Helpers, type: :feature
  # config.after(:each, type: :feature) { Warden.test_reset! }

  # Gets around a bug in RSpec where helper methods that are defined in views aren't
  # getting scoped correctly and RSpec returns "does not implement" errors. So we
  # can disable verify_partial_doubles if a particular test is giving us problems.
  # Ex:
  #   describe "problem test", verify_partial_doubles: false do
  #     ...
  #   end
  config.before :each do |example|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = example.metadata.fetch(:verify_partial_doubles, true)
    end
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  config.extend WithModel
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # For Devise >= 4.1.0
  # config.extend ControllerMacros, :type => :controller
end
Capybara.server_port = 4000
# Capybara.ignore_hidden_elements = true