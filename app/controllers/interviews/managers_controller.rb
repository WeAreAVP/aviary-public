# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # ManagerController
  class ManagersController < ApplicationController
    include XMLFileHandler
    before_action :authenticate_user!
    before_action :set_interview, only: %i[show edit update destroy]

    # GET /interviews
    # GET /interviews.json
    def index
      authorize! :manage, current_organization
      @interviews = Interviews::Interview.all
      @search_columns = current_organization.interview_search_column
      @display_columns = current_organization.interview_display_column
    end

    def listing
      authorize! :manage, current_organization
      respond_to do |format|
        format.html
        format.json { render json: InterviewsDatatable.new(view_context, current_organization) }
      end
    end

    # GET /interviews/1
    # GET /interviews/1.json
    def show; end

    # GET /interviews/new
    def new
      authorize! :manage, current_organization
      @interview = Interviews::Interview.new
    end

    # GET /interviews/1/edit
    def edit
      authorize! :manage, current_organization
    end

    # GET /interviews/1/export.format
    def export
      authorize! :manage, current_organization
      interview = Interviews::Interview.find(params[:id])
      export_text = Aviary::ExportOhmsInterviewXml.new.export(interview)
      doc = Nokogiri::XML(export_text.to_xml)
      error_messages = xml_validation(doc)
      if error_messages.any?
        respond_to do |format|
          format.any { redirect_to interviews_managers_path, notice: 'Something went wrong. Please try again later.' }
        end
      else
        file_name = interview.miscellaneous_ohms_xml_filename.empty? ? interview.title : interview.miscellaneous_ohms_xml_filename
        respond_to do |format|
          format.xml { send_data(export_text.to_xml, filename: "#{file_name}.xml") }
          format.any { redirect_to interviews_managers_path, notice: 'Not a valid URL.' }
        end
      end
    end

    # POST /interviews
    # POST /interviews.json
    def create
      authorize! :manage, current_organization
      @interview = Interviews::Interview.new(interview_params)
      @interview.organization = current_organization
      respond_to do |format|
        if @interview.save
          format.html { redirect_to interviews_managers_path, notice: 'Interview was successfully created.' }
          format.json { render :show, status: :created, location: @interview }
        else
          format.html { render :new }
          format.json { render json: @interview.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /interviews/1
    # PATCH/PUT /interviews/1.json
    def update
      authorize! :manage, current_organization
      respond_to do |format|
        if @interview.update(interview_params)
          format.html { redirect_to interviews_managers_path, notice: 'Interview was successfully updated.' }
          format.json { render :show, status: :ok, location: @interview }
        else
          format.html { render :edit }
          format.json { render json: @interview.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /interviews/1
    # DELETE /interviews/1.json
    def destroy
      authorize! :manage, current_organization
      @interview.destroy
      respond_to do |format|
        format.html { redirect_to interviews_managers_path, notice: 'Interview was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    def update_column_info
      authorize! :manage, current_organization
      search_columns = {}
      display_columns = { 'number_of_column_fixed' => 0, 'columns_status' => {} }
      respond_to do |format|
        if params['info'].present? && JSON.parse(params['info'].to_json).present?
          JSON.parse(params['info'].to_json).each_with_index do |(order, info), _index|
            display_columns['columns_status'][order] ||= {}
            search_columns[order] = { value: info['system_name'], status: info['table_search'].to_s.to_boolean? }
            display_columns['columns_status'][order] = { value: info['system_name'], status: info['table_display'].to_s.to_boolean? }
          end
          msg = if current_organization.update(interview_search_column: search_columns.to_json, interview_display_column: display_columns.to_json)
                  t('updated_successfully')
                else
                  t('error_update')
                end
          format.json { render json: [response: msg], status: :accepted }
        else
          format.json { render json: [response: t('error_update')], status: :unprocessable_entity }
        end
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_interview
      @interview = Interviews::Interview.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def interview_params
      params.require(:interviews_interview).permit(:title, :accession_number, :interview_date, :date_non_preferred_format, :collection_id, :collection_name, :collection_link, :series_id, :series, :series_link,
                                                   :summary, :thesaurus_keywords, :thesaurus_subjects, :thesaurus_titles, :transcript_sync_data, :transcript_sync_data_translation, :media_format, :media_host, :media_url,
                                                   :media_duration, :media_filename, :media_type, :right_statement, :usage_statement, :acknowledgment, :language_info, :include_language, :language_for_translation, :miscellaneous_cms_record_id,
                                                   :miscellaneous_ohms_xml_filename, :miscellaneous_use_restrictions, :miscellaneous_sync_url, :miscellaneous_user_notes, :interview_status, :status, :avalon_target_domain, :metadata_status,
                                                   :embed_code, :media_host_account_id, :media_host_player_id, :media_host_item_id, interviewee: [], interviewer: [], keywords: [], subjects: [], format_info: [])
    end
  end
end
