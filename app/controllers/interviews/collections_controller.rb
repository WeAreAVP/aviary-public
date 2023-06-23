# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # CollectionsController
  class CollectionsController < ApplicationController
    before_action :authenticate_user!
    # GET /interview/collections
    # GET /interview/collections.json
    def index
      authorize! :manage, current_organization
      session[:interview_bulk] = [] unless request.xhr?
      @interviews = Interviews::Interview.all
      @search_columns = current_organization.interview_search_column
      @display_columns = current_organization.interview_display_column
      @collections = Collection.where(organization_id: current_organization.id)
      @users = current_organization.organization_ohms_assigned_users
    end

    def listing
      authorize! :manage, current_organization
      respond_to do |format|
        format.html
        format.json { render json: InterviewsCollectionsDatatable.new(view_context, current_organization) }
      end
    end

    def interviews
      authorize! :manage, current_organization
      session[:interview_bulk] = [] unless request.xhr?
      @interviews = Interviews::Interview.fetch_interview_list(1, 10_000_000, [], '', { collection_id: params['collection_id'] }, {}, export: false, current_organization: current_organization)
      @search_columns = current_organization.interview_search_column
      @display_columns = current_organization.interview_display_column
      @collections = Collection.where(organization_id: current_organization.id)
      @users = current_organization.organization_ohms_assigned_users
      @collection_id = ''
      @series_id = ''
      @collection_title = ''
      @series_title = ''
      records = @interviews.try(:first)
      records.each do |record|
        @collection_id = record['collection_id_ss'] if @collection_id.blank?
        @series_id = record['series_id_ss'] if @series_id.blank?
        @collection_title = record['collection_name_ss'] if @collection_title.blank?
        @series_title = record['series_ss'] if @series_title.blank?
        if @series_title.present? && @collection_title.present? && @series_id.present? && @collection_id.present?
          break
        end
      end
      render 'interviews/managers/index'
    end

    def interviews_list
      authorize! :manage, current_organization
      organization_user = OrganizationUser.find_by_user_id(current_user.id)

      respond_to do |format|
        format.html
        format.json { render json: InterviewsDatatable.new(view_context, current_organization, '', organization_user) }
      end
    end

    def export
      authorize! :manage, current_organization
      if params[:collection_id].present?
        InterviewBulkExportWorker.perform_in(1.second, params[:collection_id], current_user.id, current_organization.id)
      end
      redirect_to list_collections_path, notice: 'OHMS Interview XMLs are in progress and will be exported shortly. You will be notified via email once the export is complete. You do not need to stay on this page.'
    end
  end
end
