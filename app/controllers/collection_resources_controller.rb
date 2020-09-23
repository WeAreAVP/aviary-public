# Collection Resources Controller
class CollectionResourcesController < ApplicationController
  before_action :set_av_resource, except: %I[new show create embed_file]
  before_action :authenticate_user!, except: %I[show search_text load_head_and_tombstone_template load_resource_details_template load_time_line_template embed_file show_search_counts load_index_template load_transcript_template file_wise_counts]
  before_action :check_resource_limit, only: %I[new create]
  before_action :check_if_playlist
  load_and_authorize_resource except: %I[create search_text load_head_and_tombstone_template load_resource_details_template load_time_line_template embed_file show_search_counts load_index_template load_transcript_template file_wise_counts]
  include ApplicationHelper
  include Aviary::ResourceFileManagement

  def index
    authorize! :manage, current_organization
    session[:resource_list_params] = params
    record_last_bread_crumb(request.fullpath, 'Back to My Resources') unless request.xhr?
    session[:resource_list_bulk_edit] = [] unless request.xhr?
    session[:resource_list_params] = [] unless request.xhr?
    respond_to do |format|
      format.html
      format.json { render json: ResourcesListingDatatable.new(view_context, current_organization, params['called_from']) }
    end
  end

  def show
    id = params[:collection_resource_id].present? ? params[:collection_resource_id] : params[:id]
    @collection_resource = CollectionResource.joins(:collection).where(id: id).where(collections: { organization_id: current_organization.id }).first
    unless @collection_resource.present?
      flash[:error] = 'Resource not found'
      return redirect_to root_path
    end
    authorize! :read, @collection_resource
    @dynamic_fields = @collection_resource.all_fields
    @description_seo = @collection_resource.custom_field_value('description').try(:first)
    @collection = @collection_resource.collection
    CollectionResourcePresenter.new(@collection_resource, view_context).breadcrumb_manager('show', @collection_resource, @collection) if can? :manage, @collection_resource
    @resource_file = params[:resource_file_id] && !CollectionResourceFile.where(id: params[:resource_file_id]).empty? ? CollectionResourceFile.find(params[:resource_file_id]) : @collection_resource.collection_resource_files.order_file.first
    @detail_page = true
    @file_index = FileIndex.new
    @file_transcript = FileTranscript.new

    @selected_transcript = 0
    @selected_index = 0
    @file_indexes = {}
    @file_transcripts = {}
    session[:count_presence] = { index: false, transcript: false, description: false }
    @session_video_text_all = session[:transcript_count] = session[:index_count] = session[:description_count] = {}
    collection_resource_presenter = CollectionResourcePresenter.new(@collection_resource, view_context)
    @session_video_text_all, @selected_transcript, @selected_index, @count_file_wise = collection_resource_presenter.generate_params_for_detail_page(@resource_file, @collection_resource, session, params)
    @file_indexes, @file_transcripts, @selected_index, @selected_transcript = collection_resource_presenter.selected_index_transcript(@resource_file, @selected_index, @selected_transcript)
  end

  def file_wise_counts
    session_video_text_all = params[:search_text_val]
    collection_resource = CollectionResource.find_by_id(params[:collection_resource_id])
    count_file_wise = {}
    if collection_resource.present? && session_video_text_all.present?
      collection_resource_presenter = CollectionResourcePresenter.new(@collection_resource, view_context)
      count_file_wise = collection_resource_presenter.file_wise_count(collection_resource, count_file_wise, session_video_text_all)
    end
    response = { count_file_wise: count_file_wise }
    respond_to do |format|
      format.html { render json: response }
      format.json { render json: response }
    end
  end

  def update_metadata
    @collection_resource = CollectionResource.find(params[:collection_resource_id])
    respond_to do |format|
      if @collection_resource
        updated_field_values = {}
        av_resource_params[:collection_resource_field_values].each do |value|
          unless value['value'].empty? && value['vocabularies_id'].empty?
            if updated_field_values[value['collection_resource_field_id']].nil?
              updated_field_values[value['collection_resource_field_id']] = { field_id: value['collection_resource_field_id'], values: [] }
            end
            updated_field_values[value['collection_resource_field_id']][:values] << { value: value['value'], vocab_value: value['vocabularies_id'] }
          end
        end
        @collection_resource.batch_update_values(updated_field_values.values, true)
        @collection_resource.reindex_collection_resource unless Rails.env.test?
        @collection_resource.update(updated_at: Time.now)
        @msg = t('description_metadata_updated')
      else
        @msg = t('error_update_again')
      end
      flash[:notice] = @msg
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def load_index_template
    render plain: '' unless request.xhr?
    @resource_file = params[:resource_file_id] ? CollectionResourceFile.find_by(id: params[:resource_file_id]) : @collection_resource.collection_resource_files.order_file.first
    authorize! :read, @collection_resource
    @file_index = params['selected_index'].to_i > 0 ? FileIndex.find(params['selected_index']) : @resource_file.file_indexes.order_index.first
    @file_index_points = @file_index.file_index_points
    @total_index_points = @file_index.file_index_points.count
    render partial: 'indexes/index', locals: { size: params[:tabs_size] }
  end

  def load_transcript_template
    render plain: '' unless request.xhr?
    @listing_transcripts = {}
    @resource_file = params[:resource_file_id] ? CollectionResourceFile.find_by(id: params[:resource_file_id]) : @collection_resource.collection_resource_files.order_file.first
    authorize! :read, @collection_resource
    @file_transcript = params['selected_transcript'].to_i > 0 ? FileTranscript.find(params['selected_transcript']) : @resource_file.file_transcripts.order_transcript.first
    @file_transcript_points = @file_transcript.file_transcript_points
    @total_transcript_points = @file_transcript.file_transcript_points.count
    @can_access_transcript = @file_transcript.is_public || @collection_resource.can_view || @collection_resource.can_edit || (can? :edit, @collection_resource.collection.organization) || (can? :read, @file_transcript)
    collection_resource_presenter = CollectionResourcePresenter.new(@collection_resource, view_context)
    @session_video_text_all = collection_resource_presenter.all_params_information(params)
    @listing_transcripts, @transcript_count, @transcript_time_wise = collection_resource_presenter.transcript_point_list(@file_transcript, @file_transcript_points, @session_video_text_all)

    body_response = view_context.render 'transcripts/index', locals: { size: params[:tabs_size], xray: false }

    respond_to do |format|
      format.json { render json: { body_response: body_response, listing_transcripts: @listing_transcripts } }
    end
  end

  def load_resource_details_template
    @resource_file = params[:resource_file_id] ? CollectionResourceFile.find_by(id: params[:resource_file_id]) : @collection_resource.collection_resource_files.order_file.first
    authorize! :read, @collection_resource
    @dynamic_fields = @collection_resource.all_fields
    render partial: 'collection_resources/show/info_tabs', locals: { dynamic_fields: @dynamic_fields, search_size: params[:search_size], tabs_size: params[:tabs_size] }
  end

  def load_head_and_tombstone_template
    render partial: 'collection_resources/show/heading_and_tombstone'
  end

  # POST /av_resources
  # POST /av_resources.json
  def update_details
    if params[:av_resource_id]
      @av_resource = CollectionResource.find(params[:av_resource_id])
      respond_to do |format|
        @av_resource.status = true
        if @av_resource.update(av_resource_params)
          @msg = t('information_updated')
          format.html { redirect_to collection_av_resource_path(@av_resource.collection, @av_resource), notice: @msg }
          format.json { render :show, status: :ok, location: collection_av_resource_path(@av_resource.collection, @av_resource) }
        else
          format.html { render :edit }
          format.json { render json: @av_resource.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: t('error_update'), status: :unprocessable_entity }
      end
    end
  end

  # GET /av_resources/new
  def new
    authorize! :manage, current_organization
    @collections = Collection.where(organization_id: current_organization.id)
    unless @collections.present?
      flash[:notice] = t('add_collection_error')
      redirect_back(fallback_location: root_path)
    end

    @collection_resource = CollectionResource.new
  end

  # GET /collection_resources/1/edit
  def edit
    CollectionResourcePresenter.new(@collection_resource, view_context).breadcrumb_manager('edit', @collection_resource, @collection) if can? :manage, @collection_resource
    @collections = current_organization.collections.order('title')
  end

  # POST /collection_resources
  # POST /collection_resources.json
  def create
    @collection_resource = CollectionResource.create(av_resource_params)
    @collection_resource.reindex_collection_resource
    flash[:notice] = t('resource_created')
    redirect_to collection_collection_resource_add_resource_file_path(@collection_resource.collection, @collection_resource)
  end

  def add_resource_file
    CollectionResourcePresenter.new(@collection_resource, view_context).breadcrumb_manager('manage_file', @collection_resource, @collection) if can? :manage, @collection_resource
    @resource_files = @collection_resource.collection_resource_files.order('sort_order ASC')
  end

  # PATCH/PUT /collection_resources/1
  # PATCH/PUT /collection_resources/1.json
  def update
    respond_to do |format|
      if @collection_resource.update(av_resource_params)
        @collection_resource.reindex_collection_resource
        format.html { redirect_to edit_collection_collection_resource_path(@collection_resource.collection, @collection_resource), notice: 'Resource successfully updated.' }
        format.json { render json: '' }
      else
        @collections = current_organization.collections
        format.html { render :edit }
        format.json { render json: @collection_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def resource_file_sort
    params[:resource_file_sort].each do |key, value|
      CollectionResourceFile.find_by_id(key).update(sort_order: value)
    end
    render json: [errors: []]
  end

  def delete_resource_file
    file = @collection_resource.collection_resource_files.find(params[:resource_file_id])
    locked_transcript = file.file_transcripts.where(is_edit: true)
    if locked_transcript.present?
      flash[:error] = 'A transcript attached to this media file is in the process of being edited by another user. You cannot delete this media file until the transcript is unlocked.'
    else
      @collection_resource.delete_resource_files(params)
      flash[:notice] = t('media_file_deleted_successfully')
    end

    redirect_to collection_collection_resource_add_resource_file_path(@collection, @collection_resource)
  end

  def destroy
    locked_transcript = @collection_resource.collection_resource_files.joins(:file_transcripts).where('file_transcripts.is_edit', true)
    if locked_transcript.present?
      flash[:error] = 'A transcript that is part of this resource is in the process of being edited by another user. You cannot delete this resource until the transcript is unlocked.'
    else
      @collection_resource.destroy
      Sunspot.remove(@collection_resource)
      flash[:notice] = 'Resource deleted successfully.'
    end
    redirect_back(fallback_location: root_path)
  end

  def embed_file
    params[:embed] = 'true'
    @resource_file = CollectionResourceFile.includes(collection_resource: [:collection])
                                           .where(id: params[:resource_file_id])
                                           .where(collections: { organization_id: current_organization }).try(:first)
    authorize! :read, @resource_file
    if @resource_file.present?
      @collection_resource = @resource_file.collection_resource if params[:media_player] == 'true'
    else
      flash[:error] = 'Requested resource not found'
      redirect_to root_path
    end
  end

  private

  def check_if_playlist
    @inside_playlist = request.referrer.split('/').include?('playlists') if request.referrer.present?
  end

  def check_resource_limit
    allowed = current_organization.subscription.plan.max_resources
    used = current_organization.resource_count
    return unless allowed > 0 && allowed - used <= 0
    flash[:notice] = t('resource_limit')
    redirect_back(fallback_location: root_path)
  end

  # Use callbacks to share common setup or constraints between actions .
  def set_av_resource
    id = params[:collection_resource_id].present? ? params[:collection_resource_id] : params[:id]

    @collection_resource = CollectionResource.find(id) if id.present?
    @collection = @collection_resource.collection if @collection_resource.present?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def av_resource_params
    params.require(:collection_resource).permit(:resource_files, :collection_id, :is_featured, :access, :title, :custom_unique_identifier,
                                                :add_rss_information, :include_in_rss_podcast_feed, :keywords, :explicit, :episode_type, :episode, :season, :content,
                                                collection_resource_field_values: %i[collection_resource_id value vocabularies_id collection_resource_field_id])
  end
end
