require 'noid-rails'

Noid::Rails.configure do |config|
  config.template = '.reedeedeedk'
  config.minter_class = Noid::Rails::Minter::Db
end