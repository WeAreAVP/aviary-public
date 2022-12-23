# Collection Resource Files Controller
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CollectionResourceFilesController < ApplicationController
  before_action :authenticate_user!
  def index
    authorize! :manage, current_organization
    session[:resource_file_list_bulk_edit] = [] unless request.xhr?
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
      elsif params['check_type'] == 'change_is_cc_on'
        if params['is_cc_on'].present?
          CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit]).update(is_cc_on: params['is_cc_on'].to_i)
        else
          format.json { render json: { message: t('error_update'), errors: true, status: 'danger' } }
        end
      else
        CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit]).each do |file|
          file.update(access: params['access_type'])
        end
      end
      format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success' } }
    end
  end

  def media_thumbnail_remove
    @resource_file = CollectionResourceFile.find_by_id(params[:collection_resource_file_id]) if params[:collection_resource_file_id].present?
    render partial: 'collection_resource_files/thumbnail_remove'
  end

  def export_resource_file
    limit_resource_ids = session[:resource_file_list_bulk_edit].present? ? "id_is:(#{session[:resource_file_list_bulk_edit].join(' OR ')})" : ''
    MediaFilesBulkExportWorker.perform_in(1.second, current_organization, limit_resource_ids, current_user.id, params, current_organization.id, request.base_url)
    flash[:notice] = 'Media Files CSV export queued successfully. You will be notified via email once the export is completed.'
    redirect_back fallback_location: root_path
  end
end
