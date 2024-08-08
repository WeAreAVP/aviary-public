# AccessRequestsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::PlaylistsDatatable < Datatables::ApplicationDatatable
  delegate :link_to, :playlist_show_path, :playlist_edit_path, :playlist_path, to: :@view

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_playlists, count = playlists
    playlists_data = all_playlists.map do |playlist|
      [].tap do |column|
        column << playlist.name
        column << playlist.playlist_resources_count
        column << status(playlist.is_featured)
        column << status(playlist.public?)
        advance_action_html = links(playlist)
        column << advance_action_html
      end
    end
    [playlists_data, count]
  end

  def links(path)
    advance_action_html = ''
    advance_action_html += '&nbsp;'
    # view button
    advance_action_html += link_to 'View', playlist_show_path(path), class: 'btn-sm btn-default'
    advance_action_html += '&nbsp;'
    # edit button
    advance_action_html += link_to 'Edit', playlist_edit_path(path), class: 'btn-sm btn-success'
    advance_action_html += '&nbsp;'
    # Delete button
    advance_action_html += link_to 'Delete', 'javascript://', class: 'btn-sm btn-danger playlist_delete', data: { url: playlist_path(path), name: path.name }
    advance_action_html += '&nbsp;'
    advance_action_html
  end

  def count; end

  def playlists
    fetch_data
  end

  def status(query)
    query ? 'Yes' : 'No'
  end

  def fetch_data
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    playlists, count = Playlist.fetch_list(page, per_page, params[:search][:value], @current_organization.id)
    playlists = if sort_column == 'is_featured'
                  playlists.order(" FIELD(playlists.is_featured, true, false) #{sort_direction}")
                elsif sort_column == 'public'
                  playlists.order(" FIELD(playlists.access, true, false) #{sort_direction}")
                else
                  playlists.order(sort_column => sort_direction)
                end
    [playlists, count]
  end

  def columns
    %w[name playlist_resources_count is_featured public action]
  end
end
