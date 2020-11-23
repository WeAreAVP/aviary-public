# PlaylistsController
class PlaylistsController < ApplicationController
  include PlaylistHelper

  before_action :set_config
  before_action :set_playlist, only: %I[edit update show destroy toggle_item_in_playlist_resource add_resource_to_playlist]
  before_action :authenticate_user!, except: %I[show listing_for_add_to_playlist update_selected_tab]
  load_and_authorize_resource except: %I[listing_for_add_to_playlist]

  def index
    authorize! :manage, current_organization
    @playlists = current_organization.playlists
  end

  def export
    playlist_csv = Playlist.to_csv(current_organization)
    send_data playlist_csv, filename: "#{current_organization.name.delete(' ')}_playlist_#{Date.today}.csv", type: 'csv'
  end

  def new
    @playlist = Playlist.new
  end

  def create
    @playlist = current_organization.playlists.create(playlist_params.merge(user_id: current_user.id))
    if @playlist.save
      if request.xhr?
        collection_resource = CollectionResource.find(params[:collection_resource_id])
        collection_resource_playlist_ids = collection_resource.playlist_resources.pluck(:playlist_id)
        render partial: 'single_playlist', locals: { playlist: @playlist, collection_resource: collection_resource, collection_resource_playlist_ids: collection_resource_playlist_ids,
                                                     from_action: 'listing_for_add_to_playlist', organization: current_organization }
      else
        redirect_to playlists_path, notice: t('playlist_created')
      end
    else
      render 'new'
    end
  end

  def edit
    @playlist_resource = PlaylistResource.find_by_id(params[:playlist_resource_id])
    @collection_resource ||= @playlist_resource.collection_resource if @playlist_resource

    if @collection_resource.nil? && @playlist.playlist_resources.count > 0
      @playlist_resource = @playlist.playlist_resources.order(:sort_order).first
      redirect_to playlist_edit_path(@playlist.id, playlist_resource_id: @playlist_resource.id)
      return
    end

    begin
      @collection = @collection_resource.collection
    rescue StandardError
      @collection = nil
    end
    if @collection_resource.present?
      @resource_file = @collection_resource.collection_resource_files.find_by_id(params[:collection_resource_file_id])
      if @resource_file.nil? && @collection_resource.collection_resource_files.count > 0
        redirect_to playlist_edit_path(@playlist.id, playlist_resource_id: @playlist_resource.id, collection_resource_file_id: @collection_resource.collection_resource_files.order_file.first)
        return
      end
    end
    @current_playlist_item = @playlist_resource.playlist_items.find_by_collection_resource_file_id(@resource_file.id) if @resource_file.present?
    @playlist_files = {}
    @playlist_files = @collection_resource.collection_resource_files.order_file if @collection_resource.present? && @collection_resource.collection_resource_files.present?
    @detail_page = true
    @file_indexes = {}
    @file_transcripts = {}
    return unless @collection_resource.present?
    @file_indexes, @file_transcripts, @selected_index, @selected_transcript = CollectionResourcePresenter.new(@collection_resource, view_context).selected_index_transcript(@resource_file, @selected_index, @selected_transcript)
  end

  def update
    if @playlist.update(playlist_params.merge(user_id: current_user.id))
      redirect_to request.referer, notice: t('playlist_updated')
    else
      render 'edit'
    end
  end

  def update_selected_tab
    session[:playlist_active_tab] = params[:tabtype].present? ? params[:tabtype] : 'show_playlist'
    respond_to do |format|
      format.json { render json: '1', status: :accepted }
    end
  end

  def show
    @playlist_show = true
    @playlist_resource = PlaylistResource.find_by_id(params[:playlist_resource_id])
    @collection_resource ||= @playlist_resource.collection_resource if @playlist_resource.present?

    if (params[:playlist_resource_id].nil? || params[:collection_resource_file_id].nil?) && @playlist.playlist_resources.present?
      @playlist_resource = params[:playlist_resource_id].present? ? @playlist.playlist_resources.find(params[:playlist_resource_id]) : @playlist.playlist_resources.order(:sort_order).first
      redirect_to playlist_show_path(time_prams(params))
      return
    end

    @resource_file = @collection_resource.collection_resource_files.find_by_id(params[:collection_resource_file_id]) if @playlist_resource.present?
    begin
      @collection = @collection_resource.collection
    rescue StandardError
      @collection = nil
    end

    authorize! :read, @playlist
    @current_playlist_item = @playlist_resource.playlist_items.find_by_collection_resource_file_id(@resource_file.id) if @resource_file.present?
    @playlist_files = {}
    @playlist_files = CollectionResourceFile.where(id: @playlist_resource.playlist_items.pluck(:collection_resource_file_id)).order(:sort_order) if @playlist_resource.present? && @playlist_resource.playlist_items.present?
    @detail_page = true
    @selected_transcript = 0
    @selected_index = 0
    @file_indexes = {}
    @file_transcripts = {}
    record_last_bread_crumb(request.fullpath, "Back to <strong>#{@playlist.name}</strong>") unless request.xhr?
    @embed_params = {}
    @embed_params = embed_params(@embed_params)
    session[:count_presence] = { index: false, transcript: false, description: false }
    @session_video_text_all  = session[:transcript_count] = session[:index_count] = session[:description_count] = {}
    params[:collection_resource_id] = @collection_resource.id if !params[:collection_resource_id].present? && @collection_resource.present?
    return unless @collection_resource.present?
    collection_resource_presenter = CollectionResourcePresenter.new(@collection_resource, view_context)
    @session_video_text_all, @selected_transcript, @selected_index, @count_file_wise = collection_resource_presenter.generate_params_for_detail_page(@resource_file, @collection_resource, session, params)
    @dynamic_fields = @collection_resource.all_fields
    @file_indexes, @file_transcripts, @selected_index, @selected_transcript = collection_resource_presenter.selected_index_transcript(@resource_file, @selected_index, @selected_transcript)
  end

  def fetch_resource_list
    @resources = PlaylistResource.where(id: params[:playlist_resource_id])
    render partial: 'playlists/fetch_bulk_edit_resource_list'
  end

  def destroy
    begin
      flash[:notice] = @playlist.destroy ? t('playlist_deleted') : t('error_update_again')
    rescue StandardError
      flash[:notice] = t('error_update_again')
    end
    redirect_back(fallback_location: playlists_path)
  end

  def add_resource_to_playlist
    message = t('error_update')
    status = :unprocessable_entity
    begin
      if PlaylistPresenter.add_resource_to_playlist(params[:collection_resource_id], @playlist, current_user)
        message = t('added_to_playlist')
        status = :accepted
      end
    rescue StandardError => e
      puts e
    end
    respond_to do |format|
      format.json { render json: message, status: status }
    end
  end

  def listing_for_add_to_playlist
    organization = Organization.find(params[:organization_id])
    collection_resource = CollectionResource.find(params[:collection_resource_id])
    from_action = params['identifier']
    collection_resource_playlist_ids = collection_resource.playlist_resources.pluck(:playlist_id)
    playlists = if from_action == 'listing_resource_playlists'
                  Playlist.where(id: collection_resource_playlist_ids).includes([:playlist_resources])
                else
                  organization.playlists.includes([:playlist_resources])
                end
    render partial: 'add_to_playlist', locals: { playlists: playlists, organization: organization, collection_resource: collection_resource, from_action: from_action, collection_resource_playlist_ids: collection_resource_playlist_ids }
  rescue StandardError => e
    puts e
    format.json { render json: t('error_update'), status: :unprocessable_entity }
  end

  private

  def time_prams(params)
    param = { playlist_id: @playlist.id }
    param[:playlist_resource_id] = @playlist_resource.id if @playlist_resource.present?
    if @playlist_resource.present? && @playlist_resource.playlist_items.present?
      param[:pst] = @playlist_resource.playlist_items.order(:sort_order).first.start_time if @playlist_resource.playlist_items.order(:sort_order).first.start_time.present?
      param[:pet] = @playlist_resource.playlist_items.order(:sort_order).first.end_time if @playlist_resource.playlist_items.order(:sort_order).first.end_time.present?
      param[:collection_resource_file_id] = @playlist_resource.playlist_items.order(:sort_order).first.collection_resource_file.id
    end
    param[:share] = params[:share] if params[:share].present?
    param = embed_params(param)
    param
  end

  def embed_params(param)
    param[:embed] = true if params[:embed].present?
    param[:media_player] = true if params[:media_player].present?
    param
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :organization_id, :access,
                                     :is_featured, :thumbnail, :is_audio_only, :enable_rss)
  end
end
