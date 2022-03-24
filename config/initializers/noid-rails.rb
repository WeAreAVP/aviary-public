
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
require 'noid-rails'

Noid::Rails.configure do |config|
  config.template = '.reedeedeedk'
  config.minter_class = Noid::Rails::Minter::Db
end