# Collections Controller
class CollectionsController < ApplicationController
  before_action :set_collection, only: %I[edit update show destroy]
  before_action :authenticate_user!, except: :show
  load_and_authorize_resource
  include Aviary::BulkOperation
  include CollectionResourceHelper

  def index
    authorize! :manage, current_organization
    @collections = current_organization.collections
  end

  def show
    organization = current_organization
    if organization.nil?
      flash[:error] = 'Please go to organization page.'
      return redirect_to root_path
    end
    @collection = organization.collections.where(id: params[:id]).first
    if @collection.nil?
      flash[:error] = t('collection_not_available')
      return redirect_to root_path
    end
    record_last_bread_crumb(request.fullpath, "Back to <strong>#{@collection.title}</strong>") unless request.xhr?
    authorize! :read, @collection
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = Time.now
    if request.xhr?
      access_filter = [CollectionResource.accesses[:access_public]]
      access_filter << CollectionResource.accesses[:access_restricted] if current_user && organization.present?
      access_filter << CollectionResource.accesses[:access_private] if current_user.present? && organization.present? && current_user.organization_users.active.where(organization_id: organization.id).present?
      page_number = params[:page_number].present? ? params[:page_number].to_i : 0
      per_page = 8
      offset = page_number * per_page
      resource_where = "( collection_resources.access IN(#{access_filter.join(', ')}) )"

      @featured_collection_resources = CollectionResource.list_resources(organization, @collection.id, resource_where, false, per_page, 'collection_resources.is_featured  DESC, lower(collection_resources.title) ASC', offset)

      render json: { partial: render_to_string(partial: 'home/resources_home_inner', locals: { from_lazy_load: params[:from_lazy_load].present?, featured_resources: @featured_collection_resources,
                                                                                               collection_wise_resources: [], featured: false }) }
    else
      render 'show'
    end
  end

  def new
    @collection = Collection.new
  end

  def create
    @collection = current_organization.collections.create(collection_params)
    if @collection.save
      redirect_to collections_path, notice: t('collection_created')
    else
      render 'new'
    end
  end

  def edit
    @collection_resource = @collection.collection_resources.first
    if request.xhr?
      @resource_file = @collection_resource.try { |collection_resource| collection_resource.collection_resource_files.order_file.first }
      @data_hash = PreviewScript.new(@collection, params).update_data_hash(eval(params['previous_hash']))
      render partial: 'collection_resource_preview', locals: { data_hash: @data_hash, resource_file: @resource_file }
    else
      @dynamic_fields = @collection.all_fields
      @resource_file = @collection_resource.try { |collection_resource| collection_resource.collection_resource_files.order_file.first }
      @detail_page = false
      @data_hash = PreviewScript.new(@collection).data_hash(@collection_resource, @dynamic_fields)
    end
    current_organization.update_resource_search_column_fields(true)
    current_organization.update_resource_column_fields(true)
  end

  def update
    if @collection.update(collection_params)
      @collection.update_field_settings(params['collection_settings'].values)
      updated_field_values = {}
      params['collection']['collection_field_values_attributes'].each do |value|
        if value['collection_field_id'].present?
          if updated_field_values[value['collection_field_id']].nil?
            updated_field_values[value['collection_field_id']] = { field_id: value['collection_field_id'], values: [] }
          end
          updated_field_values[value['collection_field_id']][:values] << { value: value['value'], vocab_value: '' }
        end
      end
      @collection.batch_update_values(updated_field_values.values, true)
      redirect_to collections_path, notice: t('collection_updated')
    else
      @dynamic_fields = @collection.all_fields
      @collection_resource = @collection.collection_resources.first
      @resource_file = @collection_resource.try { |collection_resource| collection_resource.collection_resource_files.order_file.first }
      @data_hash = PreviewScript.new(@collection).data_hash(@collection_resource, @dynamic_fields)
      render 'edit'
    end
  end

  def list_resources
    authorize! :manage, current_organization
    collection = this_collection
    session[:resource_list_params] = params
    session[:resource_list_bulk_edit] = [] unless request.xhr?
    session[:resource_list_params] = [] unless request.xhr?
    record_last_bread_crumb(request.fullpath, "Back to <strong>#{@collection.title}</strong>") unless request.xhr?
    respond_to do |format|
      format.html
      format.json { render json: ResourcesListingDatatable.new(view_context, collection) }
    end
  end

  def set_collection
    @collection = this_collection
  end

  def create_custom_fields
    @collection = this_collection
    unless params['custom_fields_field']['system_name'].present?
      params['custom_fields_field']['system_name'] = params['custom_fields_field']['label'].parameterize.underscore
    end

    unless params['custom_fields_field']['system_name'].present?
      params['custom_fields_field']['system_name'] = params['custom_fields_field']['label'].parameterize.underscore
    end
    params['custom_fields_field']['is_vocabulary'] = 0
    unless params['custom_fields_field']['vocabulary'].empty?
      params['custom_fields_field']['is_vocabulary'] = 1
      params['custom_fields_field']['vocabulary'] = params['custom_fields_field']['vocabulary'].split(',')
    end
    id = nil
    unless params['meta_field_id'].empty?
      id = params['meta_field_id'].to_i
    end
    unless params['custom_fields_field']['dropdown_options'].empty?
      params['custom_fields_field']['dropdown_options'] = params['custom_fields_field']['dropdown_options'].split(',')
    end
    @collection.create_update_dynamic(params['custom_fields_field'], id)
    redirect_back(fallback_location: edit_collection_path(@collection))
  end

  def update_sort_fields
    @collection.update_field_settings(params['collection_resource_field'].values, 'CollectionResource')
    render json: { status: 'success' }
  end

  def new_edit_custom_field
    @collection = this_collection
    if params[:methodtype] == 'new'
      @meta_field = CustomFields::Field.new
    elsif params[:methodtype] == 'edit'
      @meta_field = CustomFields::Field.find_by_id(params[:collection_meta_id])
    end
    @source_type = 'CollectionResource'
    render partial: 'collection_custom_fields', locals: { meta_field: @meta_field, collection: @collection, source_type: @source_type }
  end

  def delete_custom_meta_fields
    @collection = this_collection
    @collection.delete_dynamic(params[:meta_field_id])
    flash[:notice] = 'Custom field deleted successfully.'
    redirect_back(fallback_location: edit_collection_path(@collection))
  end

  def destroy
    begin
      locked_transcript = @collection.collection_resources.joins(:collection_resource_files)
                                     .includes(collection_resource_files: [:file_transcripts])
                                     .where(file_transcripts: { is_edit: true })
      @collection.status = Collection.statuses[:deleted]
      if locked_transcript.present?
        flash[:error] = 'A transcript that is part of this collection is in the process of being edited by another user. You cannot delete this collection until the transcript is unlocked.'
      elsif @collection.save
        DeleteCollectionsWorker.perform_in(1.minutes)
        flash[:notice] = t('collection_deleted')
      else
        flash[:notice] = t('error_update_again')
      end
    rescue StandardError
      flash[:notice] = t('error_update_again')
    end
    redirect_back(fallback_location: root_path)
  end

  def export
    if params[:export_type] == 'collection'
      collection_csv = current_organization.collections.first.to_csv
      send_data collection_csv, filename: "#{current_organization.name.delete(' ')}_collection_#{Date.today}.csv", type: 'csv'
    elsif params[:export_type] == 'resources'
      resources_csv = if params[:collection_id].present?
                        to_csv(params[:collection_id], request)
                      else
                        to_csv(current_organization.collections.map(&:id), request)
                      end
      send_data resources_csv, filename: "#{current_organization.name.delete(' ')}_collection_resources_#{Date.today}.csv", type: 'csv'
    end
  end

  def import
    collection = Collection.find(params[:id])
    file_data = params[:importCSV]
    response = Aviary::ImportCsv.new.process(file_data)
    return render json: { error: true, message: response } if response.is_a? String
    collection.global_ip_list = response.to_json
    collection.save
    render json: { errors: false }
  end

  def collection_resource_field_params
    params.require(:collection_resource_field).permit(:is_required, :is_public, :is_repeatable, :is_visible, :is_tombstone, :sort_order,
                                                      field_type: %i[label column_type help_text is_vocabulary source_type system_name], vocabulary: %i[value])
  end

  def collection_params
    params.require(:collection).permit(:title, :about, :image, :is_public, :is_featured, :click_through, :conditions_for_access, :automated_access_approval, :period_of_access,
                                       :time_period, :target_of_access, :access_request_approval_email, :accessible_details_to_email, :resource_link_to_approval_email, :display_banner,
                                       :global_ip_enabled, :global_ip_list, :subject, :from_name, :bcc_request_email, :is_audio_only, :disable_player, :banner_slider_resources,
                                       :banner_type, :default_tab_selection, :enable_rss, :enable_resource_search, :search_resource_placeholder, :favicon, :enable_itc_autoscroll, :card_image)
  end

  def permit_sort(value)
    value.permit(:is_visible, :is_tombstone, :sort_order).to_h
  end

  private

  def this_collection
    current_organization.collections.find_by_id(params[:id]) if params[:id]
  end

  def to_csv(collection_ids, _request)
    limit_resource_ids = session[:resource_list_bulk_edit].present? ? "AND id_is:(#{session[:resource_list_bulk_edit].join(' OR ')})" : ''
    limit_condition = collection_ids.class == String ? "collection_id_is:#{collection_ids} #{limit_resource_ids} " : "collection_id_is:(#{collection_ids.join(' OR ')}) #{limit_resource_ids}"
    resources = CollectionResource.fetch_resources(0, 0, 'collection_id_is', 'desc', session[:resource_list_params], limit_condition, export: true, current_organization: current_organization)

    attributes = ['aviary ID', 'Resource User Key']
    if current_organization.present? && !current_organization.resource_table_column_detail.blank? && !JSON.parse(current_organization.resource_table_column_detail).blank?
      JSON.parse(current_organization.resource_table_column_detail)['columns_status'].each do |_, value|
        if !value['status'].blank? && value['status'] == 'true'
          attributes << display_field_title_table(value['value'])
        end
      end
    end
    %w[PURL URL Embed].map { |name| attributes << name }
    extra_column = 0
    csv_rows = []

    csv_rows << attributes
    resources.first.each do |resource|
      link = collection_collection_resource_details_url(collection_id: resource['collection_id_is'],
                                                        collection_resource_id: resource['id_is'], host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization))
      purl = ''
      resource_file_embed = []
      embeded_resource = "<iframe src='#{link}?embed=true' height='400' width='1200' style='width: 100%'></iframe>"
      begin
        purl = noid_url(noid: resource['noid_ss'], host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization))
        db_resource = CollectionResource.find_by_id(resource['id_is'])
        db_resource.collection_resource_files.each do |resource_file|
          resource_file_embed << "<iframe src='#{embed_file_url(host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization), resource_file_id: resource_file.id)}' height='400' width='600'></iframe>"
        end
        extra_column = resource_file_embed.count if resource_file_embed.count > extra_column
      rescue StandardError => e
        puts e.backtrace.join("\n")
      end
      row = [resource['id_is'], '']
      if resources.fourth.resource_table_column_detail
        JSON.parse(resources.fourth.resource_table_column_detail)['columns_status'].each do |_, value|
          if !value['status'].blank? && value['status'] == 'true'
            row << if value['value'] == 'description_duration_ss'
                     resource[value['value']].present? ? time_to_duration(resource[value['value']]) : '00:00:00'
                   elsif value['value'] == 'collection_title'
                     resources.third[resource['collection_id_is'].to_s]
                   elsif value['value'] == 'access_ss'
                     resource[value['value']].gsub('access_', '').titleize.strip
                   elsif !resource[value['value']].blank?
                     resource[value['value']].class == Array ? resource[value['value']].join(' | ') : resource[value['value']]
                   else
                     ''
                   end
          end
        end
      end
      row << purl
      row << link
      row << embeded_resource

      resource_file_embed.map { |name| row << name }
      csv_rows << row
    end
    (1..extra_column).each do |item|
      csv_rows[0] << "Media Embed #{item}"
    end
    CSV.generate(headers: true) do |csv|
      csv_rows.map { |row| csv << row }
    end
  end
end
