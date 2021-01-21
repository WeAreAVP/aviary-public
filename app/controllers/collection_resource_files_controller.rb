# Collection Resource Files Controller
class CollectionResourceFilesController < ApplicationController
  before_action :authenticate_user!
  def index
    authorize! :manage, current_organization
    session[:resource_file_list_bulk_edit] = []
    respond_to do |format|
      format.html
      format.json { render json: ResourceFilesDatatable.new(view_context, current_organization) }
    end
  end

  def bulk_resource_file_edit
    respond_to do |format|
      format.html
      if params['check_type'] == 'bulk_delete'
        CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit]).each(&:destroy)
      elsif params['check_type'] == 'downloadable'
        CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit]).each do |file|
          file.update(is_downloadable: ActiveRecord::Type::Boolean.new.cast(params['is_downloadable']), downloadable_duration: params[:downloadable_duration], download_enabled_for: params[:download_enabled_for])
        end
      else
        CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit]).each do |file|
          file.update(access: params['access_type'])
        end
      end
      render json: { message: t('updated_successfully'), errors: false, status: 'success' }
    end
  end

  def media_thumbnail_remove
    @resource_file = CollectionResourceFile.find_by_id(params[:collection_resource_file_id]) if params[:collection_resource_file_id].present?
    render partial: 'collection_resource_files/thumbnail_remove'
  end

  def export_resource_file
    limit_resource_ids = session[:resource_file_list_bulk_edit].present? ? "id_is:(#{session[:resource_file_list_bulk_edit].join(' OR ')})" : ''
    resources_csv = CollectionResourceFile.to_csv(current_organization, request.base_url, limit_resource_ids, params)
    send_data resources_csv, filename: "#{current_organization.name.delete(' ')}_collection_resources_file_#{Date.today}.csv", type: 'csv'
  end
end
