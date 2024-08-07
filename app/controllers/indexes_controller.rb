# controllers/indexes_controllers.rb
#
# IndexesController
# The module is written to store the index and transcript for the collection resource file
# Currently supports OHMS XML and WebVtt format
# Nokogiri, webvtt-ruby gem is needed to run this module successfully
# dry-transaction gem is needed for adding transcript steps to this process
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class IndexesController < ApplicationController
  before_action :authenticate_user!
  include IndexesHelper

  def index
    authorize! :manage, current_organization
    session[:file_index_bulk_edit] = [] unless request.xhr?
    respond_to do |format|
      format.html
      format.json { render json: Datatables::IndexesDatatable.new(view_context, current_organization, params['called_from'], params[:additionalData]) }
    end
  end

  def bulk_file_index_edit
    respond_to do |format|
      format.html
      if params['check_type'] == 'bulk_delete'
        FileIndex.where(id: session[:file_index_bulk_edit]).each(&:destroy)
      elsif params['check_type'] == 'change_status'
        FileIndex.where(id: session[:file_index_bulk_edit]).each do |index|
          index.update(is_public: params['access_type'] == 'yes')
        end
      end
      format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success', action: 'bulk_file_index_edit' } }
    end
  end

  def create
    FileIndex.transaction do
      _success, is_new = params[:file_index_id] ? [update_file_index, false] : [create_file_index, true]

      process_associated_file(is_new)
    rescue StandardError => ex
      add_errors unless @file_index.errors.present?
      Rails.logger.error "#{ex.message}\n#{ex.backtrace[1..5].join("\n")}"

      raise ActiveRecord::Rollback
    end

    respond_to do |format|
      format.json { render json: [errors: @file_index.errors] }
    end
  end

  def sort
    params[:sort_list]&.each_with_index do |id, index|
      FileIndex.where(id: id).update_all(sort_order: index + 1)
    end
    respond_to do |format|
      format.json { render json: [errors: []] }
    end
  end

  def destroy
    file_index = FileIndex.find(params[:id])
    file_index.destroy
    flash[:notice] = 'Index was successfully deleted.'
    redirect_back(fallback_location: root_path)
  end

  def show_index
    authorize! :manage, current_organization
    @resource_file = CollectionResourceFile.find(params[:resource_file_id])
    @collection_resource = CollectionResource.find(@resource_file.collection_resource_id)
    @collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
    @index_columns_collection = @collection_field_manager.sort_fields(
      @collection_field_manager.collection_resource_field_settings(@collection_resource.collection, 'index_fields').index_fields, 'sort_order'
    )

    if params[:file_index_id].nil?
      @file_index_point = []
    else
      @file_index = FileIndex.find(params[:file_index_id])
      @file_index_point = @file_index.file_index_points
    end
    render template: 'indexes/form/show'
  end

  def add_index
    authorize! :manage, current_organization
    @resource_file = CollectionResourceFile.find(params[:resource_file_id])
    @collection_resource = CollectionResource.find(@resource_file.collection_resource_id)
    @file_index_point = FileIndexPoint.new
    @file_index_point.start_time = params[:time] if params[:time].present?
    if params[:file_index_id].present? && !params[:file_index_id].empty?
      @file_index = FileIndex.find(params[:file_index_id])
      @file_index_points = @file_index.file_index_points
    end
    render template: 'indexes/form/new'
  end

  def create_index
    authorize! :manage, current_organization
    @resource_file = CollectionResourceFile.find(params[:file_index_point][:resource_file_id])
    @collection_resource = CollectionResource.find(@resource_file.collection_resource_id)
    if params[:file_index_point][:file_index_id].present?
      @file_index = FileIndex.find(params[:file_index_point][:file_index_id])
    else
      @file_index = FileIndex.new({
                                    collection_resource_file_id: @resource_file.id,
                                    title: "#{@collection_resource.title} #{Time.now.strftime('%m-%d-%Y %k:%M')}",
                                    user_id: current_user.id,
                                    language: 'en'
                                  })
      @file_index.save(validate: false)
    end
    @file_index_point = FileIndexPoint.new(file_index_point_params)
    @file_index_point.file_index_id = @file_index.id
    @file_index_point.start_time = human_to_seconds(params[:file_index_point][:start_time]).to_f
    @file_index_point = set_aviary_index_point_values(@file_index_point, params)

    respond_to do |format|
      if @file_index_point.save
        format.html { redirect_to redirect_url, notice: 'Index segment was successfully saved.' }
        format.json { render :show_index, status: :created, location: @file_index_point }
      else
        format.html { render template: 'indexes/form/new' }
        format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_index
    authorize! :manage, current_organization

    @resource_file = CollectionResourceFile.find(params[:resource_file_id])
    @collection_resource = CollectionResource.find(@resource_file.collection_resource_id)
    @file_index = FileIndex.find(params[:file_index_id])

    @file_index_point = FileIndexPoint.find(params[:file_index_point_id])
    @file_index_point.update(file_index_point_params)
    @file_index_point.start_time = human_to_seconds(params[:file_index_point][:start_time]).to_f
    @file_index_point = set_aviary_index_point_values(@file_index_point, params)
    respond_to do |format|
      if @file_index_point.save
        format.html { redirect_to redirect_url, notice: 'Index segment was successfully saved.' }
        format.json { render :show_index, status: :created, location: @file_index_point }
      else
        format.html { render template: 'indexes/form/edit' }
        format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_partial
    authorize! :manage, current_organization
    @file_index = FileIndex.find(params[:file_index_id])
    @file_index.title = params[:file_index][:title]

    if @file_index.save
      render json: { message: 'File Index updated successfully.', status: 'success', file_index: @file_index }
    else
      render json: { message: 'Unable to update File Index', status: 'danger' }
    end
  end

  def destroy_index
    authorize! :manage, current_organization
    file_index_point = FileIndexPoint.find(params[:index_file_point_id])
    file_index = FileIndex.find(file_index_point.file_index_id)
    update_end_time(file_index_point)
    respond_to do |format|
      format.html { redirect_to show_index_file_path(file_index.collection_resource_file_id, file_index.id), notice: 'Index segment was successfully deleted.' }
    end
  end

  def edit_index
    authorize! :manage, current_organization
    @resource_file = CollectionResourceFile.find(params[:resource_file_id])
    @collection_resource = CollectionResource.find(@resource_file.collection_resource_id)
    @file_index = FileIndex.find(params[:file_index_id])
    @file_index_points = @file_index.file_index_points
    @file_index_point = FileIndexPoint.find(params[:file_index_point_id])
    @previous_index_point, @next_index_point = adjacent_index_points
    @forward_duration, @backward_duration = retrieve_skip_durations

    set_thesaurus
    render template: 'indexes/form/edit'
  end

  def set_thesaurus
    thesaurus_settings = ::Thesaurus::ThesaurusSetting.where(organization_id: current_organization.id, is_global: true, thesaurus_type: 'resource').try(:first)
    @thesaurus_keywords = thesaurus_settings.thesaurus_keywords if thesaurus_settings.present?
    @thesaurus_subjects = thesaurus_settings.thesaurus_subjects if thesaurus_settings.present?
  end

  def update_index_point_title
    authorize! :manage, current_organization
    @file_index_point = FileIndexPoint.find(params[:file_index_point_id])
    @file_index_point.title = params[:file_index_point][:title]

    if @file_index_point.save
      render json: { message: 'Index Segment Title updated successfully.', status: 'success' }
    else
      render json: { message: 'Unable to update File Index Point title.', status: 'danger' }
    end
  end

  private

  def update_associated_file_file_name
    return unless should_update_associated_file_file_name?

    @file_index.associated_file_file_name = params[:file_index][:associated_file_file_name]
  end

  def should_update_associated_file_file_name?
    !params[:file_index][:assocated_file].present? && params[:file_index][:associated_file_file_name].present?
  end

  def create_file_index
    @file_index = FileIndex.new(file_index_params)
    @file_index.user = current_user
    resource_file = CollectionResourceFile.find(params[:resource_file_id])
    @file_index.collection_resource_file = resource_file
    @file_index.sort_order = resource_file.file_indexes.length + 1
    @file_index.save!
  end

  def update_file_index
    @file_index = FileIndex.find(params[:file_index_id])
    update_associated_file_file_name
    @file_index.update!(file_index_params)
  end

  def process_associated_file(is_new)
    return unless file_index_params[:associated_file].present?

    Aviary::IndexTranscriptManager::IndexManager.new.process(@file_index, is_new)
  end

  def add_errors
    errors = @file_index&.file_index_points&.map do |point|
      point.errors.map(&:full_message)
    end

    @file_index.errors.add(
      :associated_file,
      errors.flatten.uniq
    )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def file_index_params
    params.require(:file_index).permit(:title, :associated_file, :is_public, :language, :description)
  end

  def file_index_point_params
    params.require(:file_index_point).permit(:id, :start_time, :title, :synopsis, :partial_script, :keywords, :subjects, :gps_latitude, :gps_zoom, :gps_description, :gps_points, :hyperlinks)
  end

  def redirect_url
    start_time = @file_index_point.start_time
    start_time = params[:time] if params[:new].present? && params[:time].present?

    return "#{add_index_file_path(@resource_file.id, @file_index.id)}?time=#{start_time}" if params[:new].present?

    "#{show_index_file_path(@resource_file.id, @file_index.id)}?time=#{start_time}"
  end
end
