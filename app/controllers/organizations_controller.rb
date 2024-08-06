# controllers/organizations_controller.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OrganizationsController < ApplicationController
  before_action :set_organization, only: %I[edit update show display_settings color_contrast autocomplete_resources]
  before_action :authenticate_user!, except: %I[index show confirm_invite]
  include Aviary::ManageOrganization

  def index
    @organizations = Organization.active_orgs
    @organizations = @organizations.where('name LIKE (?)', "#{params[:title]}%") if params[:title].present?
  end

  def update_resource_column_sort
    authorize! :manage, current_organization
    respond_to do |format|
      format.html
      if current_organization.update(resource_table_column_detail: { number_of_column_fixed: params[:number_of_column_fixed], columns_status: params[:columns_status] }.to_json, resource_table_search_columns: params[:columns_search_status].to_json)
        format.json { render json: { message: t('updated_successfully'), errors: false } }
      else
        format.json { render json: { message: t('error_update'), errors: true } }
      end
    end
  end

  def update_resource_file_column
    authorize! :manage, current_organization
    respond_to do |format|
      format.html
      if current_organization.update(resource_file_display_column: { number_of_column_fixed: params[:number_of_column_fixed], columns_status: params[:columns_status] }.to_json, resource_file_search_column: params[:columns_search_status].to_json)
        format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success' } }
      else
        format.json { render json: { message: t('error_update'), errors: true, status: 'danger' } }
      end
    end
  end

  # POST: file index columns management
  def update_file_index_column
    authorize! :manage, current_organization
    respond_to do |format|
      format.html
      if current_organization.update(file_index_display_column: { number_of_column_fixed: params[:number_of_column_fixed], columns_status: params[:columns_status] }.to_json, file_index_search_column: params[:columns_search_status].to_json)
        format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success' } }
      else
        format.json { render json: { message: t('error_update'), errors: true, status: 'danger' } }
      end
    end
  end

  def update_file_transcript_column
    authorize! :manage, current_organization
    respond_to do |format|
      format.html
      if current_organization.update(transcript_display_column: { number_of_column_fixed: params[:number_of_column_fixed], columns_status: params[:columns_status] }.to_json, transcript_search_column: params[:columns_search_status].to_json)
        format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success' } }
      else
        format.json { render json: { message: t('error_update'), errors: true, status: 'danger' } }
      end
    end
  end

  def confirm_invite
    organization_user = OrganizationUser.find_by(token: params[:token])
    if organization_user.present?
      organization_user.update(status: true, token: nil)
      message = 'Your new status has been confirmed!'
    else
      message = 'Not a valid confirmation token.'
    end
    redirect_to root_url, notice: message
  end
end
