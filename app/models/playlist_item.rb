# PlaylistItem
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
class PlaylistItem < ApplicationRecord
  include Aviary::PlaylistManager

  belongs_to :playlist, counter_cache: (ENV['RAILS_ENV'] != 'test')
  belongs_to :playlist_resource, counter_cache: (ENV['RAILS_ENV'] != 'test')
  belongs_to :collection_resource
  belongs_to :collection_resource_file

  after_commit :update_duration_playlist unless Rails.env.test?
end
