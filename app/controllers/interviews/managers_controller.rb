# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # ManagerController
  class ManagersController < ApplicationController
    include XMLFileHandler
    include Aviary::BulkOperation
    include Aviary::ZipperService
    before_action :authenticate_user!
    before_action :set_interview, only: %i[show edit update destroy]

    # GET /interviews
    # GET /interviews.json
    def index
      authorize! :manage, current_organization
      session[:interview_bulk] = [] unless request.xhr?
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

    # GET /interviews/bulk_edit
    def bulk_edit; end

    def bulk_interview_edit
      if params['check_type'] == 'bulk_delete'
        Interviews::Interview.where(id: session[:interview_bulk]).each(&:destroy) if session[:interview_bulk].present?
        respond_to do |format|
          format.html { redirect_to interviews_managers_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'download_xml'
        self.tmp_user_folder = "public/reports/archive_#{current_user.id}_#{Time.now.to_i}"
        dos_xml = []
        dos_xml_files = []
        FileUtils.mkdir_p(tmp_user_folder) unless Dir.exist?(tmp_user_folder)
        session[:interview_bulk].each do |single_interview|
          interview = Interviews::Interview.find_by(id: single_interview)
          if interview.present?
            Rails.logger.error interview
            export_text = Aviary::ExportOhmsInterviewXml.new.export(interview)
            doc = Nokogiri::XML(export_text.to_xml)
            error_messages = xml_validation(doc)
            unless error_messages.any?
              Rails.logger.error dos_xml
              dos_xml << { xml: export_text.to_xml, title: interview.title, id: interview.id }
            end
          end
        end
        if dos_xml.present?
          dos_xml.each do |single_dos_xml|
            file_name = 'interview_xml_' + single_dos_xml[:title].to_s.parameterize.underscore + '_' + single_dos_xml[:id].to_s + '_' + Time.now.to_i.to_s + '.xml'
            File.open(File.join(tmp_user_folder, file_name), 'wb') do |file|
              file.write(single_dos_xml[:xml])
            end
            dos_xml_files << file_name
          end
        end
        process_and_create_zip_file(dos_xml_files)
        send_file(Rails.root.join("#{tmp_user_folder}.zip"), type: 'application/zip', filename: "export_xml_interview_#{Time.now.to_i}.zip", disposition: 'attachment')
        # FileUtils.rm_rf([tmp_user_folder, "#{tmp_user_folder}.zip"])
      end
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

    def import_metadata_xml
      file_data = params[:importXML]
      response_body = {}
      file_data.each do |data|
        response = Aviary::ImportOhmsInterviewXml.new.import(data, current_organization, current_user)
        response_body = if response.is_a?(Array)
                          { error: true, message: response.first.to_s.capitalize + ' ' + response.second.first }
                        elsif response.is_a?(String)
                          { error: true, message: response }
                        else
                          { errors: false }
                        end
        if response_body[:errors]
          break
        end
      end
      render json: response_body
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
