# Playlist Presenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class PlaylistPresenter < BasePresenter
  def self.add_resource_to_playlist(collection_resource_id, playlists, current_user, sorter = nil)
    collection_resource = CollectionResource.find(collection_resource_id)
    if collection_resource.present? && playlists.present?
      current_sort = if sorter.present?
                       sorter
                     else
                       (playlists.playlist_resources_count.present? ? playlists.playlist_resources_count.to_i : 0) + 1
                     end
      playlist_resource = PlaylistResource.new(collection_resource_id: collection_resource.id,
                                               playlist_id: playlists.id,
                                               name: collection_resource.title,
                                               user: current_user,
                                               organization: playlists.organization,
                                               description: '',
                                               sort_order: current_sort,
                                               duration: 0)
      if playlist_resource.valid?
        playlist_resource.save
        collection_resource.collection_resource_files.order('sort_order ASC').each_with_index do |single_resource_file, _index|
          playlist_item = playlist_resource.playlist_items.new(
            playlist_id: playlist_resource.playlist_id,
            collection_resource_id: collection_resource_id,
            collection_resource_file_id: single_resource_file.id,
            playlist_resource_id: playlist_resource.id,
            sort_order: single_resource_file.sort_order,
            start_time: nil,
            end_time: nil
          )
          playlist_item.save if playlist_item.valid?
        end
        return true
      end
    end

    false
  end
end
