# Playlist Helper
module PlaylistHelper
  def set_playlist
    @playlist = Playlist.find_by_id(params[:playlist_id] || params[:id]) if params[:playlist_id] || params[:id]
    if @playlist.nil?
      flash[:error] = 'Playlist not found.'
      redirect_to root_path
    else
      @playlist
    end
  end

  def set_playlist_resource
    @playlist_resource = PlaylistResource.find_by_id(params[:playlist_resource_id] || params[:id]) if params[:playlist_resource_id] || params[:id]
  end

  def set_playlist_item
    @playlist_item = PlaylistResource.find_by_id(params[:playlist_item_id] || params[:id]) if params[:playlist_item_id] || params[:id]
  end

  def set_config
    @inside_playlist = true
    @playlist_controller = controller_name
    @playlist_action = action_name
  end

  def set_json_variables(msg = t('error_update'), status = :unprocessable_entity)
    @json_message = msg
    @json_status = status
  end

  def respond_with_json(message = nil, status = nil)
    respond_to do |format|
      format.json { render json: message || @json_message, status: status || @json_status }
    end
  end
end
