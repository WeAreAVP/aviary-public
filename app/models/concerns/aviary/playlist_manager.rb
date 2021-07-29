# models/concerns/playlist_manager.rb
# Module Aviary::PlaylistManager
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary::PlaylistManager
  extend ActiveSupport::Concern

  def update_duration_playlist
    duration_calc = 0.0
    begin
      reload
    rescue StandardError => ex
      Rails.logger.error ex
    end
    playlist.playlist_items.each do |single_file|
      if PlaylistItem.find(single_file.id).present?
        current_duration = single_file.collection_resource_file.duration
        current_duration = (single_file.end_time - single_file.start_time) if single_file.start_time.present? & single_file.end_time.present?
        duration_calc += current_duration unless current_duration.blank?
      end
    end
    playlist.duration = duration_calc
    playlist.save
  rescue StandardError => ex
    Rails.logger.error ex
  end
end
