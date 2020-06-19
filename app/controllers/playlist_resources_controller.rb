# PlaylistResourcessController
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
class PlaylistResourcesController < ApplicationController
  include PlaylistHelper
  include Aviary::SearchManagement
  before_action :set_config
  before_action :set_playlist
  before_action :authenticate_user!, except: %I[search_text list_playlist_items]
  before_action :set_playlist_resource, only: %I[toggle_item update_description]
  before_action :set_json_variables

  def toggle_item
    @playlist_item = @playlist_resource.playlist_items.find_by_collection_resource_file_id(params[:mediafile])
    crf = CollectionResourceFile.find(params[:mediafile])
    if @playlist_item.nil?
      set_json_variables({ state: 'success', action: 'added', msg: 'Added to playlist' }, 200) if create_playlist_item(crf)
    elsif params[:time_only].present? && @playlist_resource.playlist_items.where(playlist_id: @playlist.id, collection_resource_id: @playlist_resource.collection_resource_id,
                                                                                 collection_resource_file_id: crf.id).update(start_time: params[:start_time], end_time: params[:end_time])
      set_json_variables({ state: 'success', action: 'updated', msg: 'Updated start/end time' }, 200)
    elsif @playlist_resource.playlist_items.length > 1 && @playlist_item.destroy
      set_json_variables({ state: 'success', action: 'deleted', msg: 'Deleted from playlist' }, 200)
    else
      message = @playlist_resource.playlist_items.length <= 1 ? 'Cannot deleted last file from playlist resource' : t('error_update')
      set_json_variables({ state: 'danger', action: 'deleted', msg: message }, 200)
    end

    respond_with_json
  end

  def sort
    params[:resources].each do |key, value|
      plr = @playlist.playlist_resources.find_by(id: key)
      plr.update(sort_order: value.to_i) if plr.present?
    end
    respond_with_json('Success', 200)
  end

  def list_playlist_items
    @playlist_show = params[:view_type].to_boolean?
    @playlist_resource = PlaylistResource.find_by_id(params[:playlist_resource_id])
    @collection_resource ||= @playlist_resource.collection_resource if @playlist_resource
    @playlist_resources = @playlist.playlist_resources.order(:sort_order).includes(:organization, :collection_resource, :playlist_items).offset(params[:per_page].to_i * params[:page_number].to_i).limit(params[:per_page])
    if params[:query].present?
      @playlist_resources = @playlist_resources.where('name LIKE ? OR description LIKE ? ', "%#{params[:query]}%", "%#{params[:query]}%")
    end

    @playlist_resources
    render partial: 'playlists/list_playlist_items'
  end

  def update_description
    flag = if params[:playlist_resource].present? && params[:playlist_resource][:title].present?
             @playlist_resource.update(name: params[:playlist_resource][:title])
           elsif params[:content].present?
             @playlist_resource.update(description: params[:content])
           else
             false
           end
    if flag
      set_json_variables({ state: 'success', action: 'Update Description', msg: 'Updated description successfully.' }, 200)
    else
      set_json_variables({ state: 'failure', action: 'Update Description', msg: 'Could not update description, please try again.' }, 200)
    end
    respond_with_json
  end

  def bulk_delete
    PlaylistResource.where(id: params[:playlist_resource_id]).destroy_all
    sort_manager(@playlist.playlist_resources)
    set_json_variables({ state: 'success', action: 'deleted', msg: 'Deleted selected resources from playlist.' }, 200)
    respond_with_json
  rescue StandardError => ex
    Rails.logger.error ex
    set_json_variables({ state: 'danger', action: 'deleted', msg: 'Could not delete select resources from playlist.' }, 200)
    respond_with_json
  end

  def destroy
    PlaylistResource.find(params[:id]).destroy
    sort_manager(@playlist.playlist_resources)
    flash[:notice] = 'Resource from Playlist was successfully deleted.'
    redirect_back(fallback_location: root_path)
  rescue StandardError => ex
    Rails.logger.error ex
    flash[:notice] = t('error_update_again')
    redirect_back(fallback_location: root_path)
  end

  private

  def create_playlist_item(collection_resource_file)
    start_time = params[:mediafile_current] == params[:mediafile] ? params[:start_time] : nil
    end_time = params[:mediafile_current] == params[:mediafile] ? params[:end_time] : nil

    @playlist_resource.playlist_items.create(playlist_id: @playlist.id,
                                             collection_resource_id: @playlist_resource.collection_resource_id,
                                             collection_resource_file_id: collection_resource_file.id,
                                             sort_order: collection_resource_file.sort_order,
                                             start_time: start_time,
                                             end_time: end_time)
  end

  def sort_manager(playlist_resources)
    return unless playlist_resources.present?
    playlist_resources.each_with_index do |value, key|
      value.update(sort_order: key + 1)
    end
  rescue StandardError => ex
    puts ex
  end
end
