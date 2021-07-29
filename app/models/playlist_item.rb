# PlaylistItem
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class PlaylistItem < ApplicationRecord
  include Aviary::PlaylistManager

  belongs_to :playlist, counter_cache: (ENV['RAILS_ENV'] != 'test')
  belongs_to :playlist_resource, counter_cache: (ENV['RAILS_ENV'] != 'test')
  belongs_to :collection_resource
  belongs_to :collection_resource_file

  after_commit :update_duration_playlist unless Rails.env.test?
end
