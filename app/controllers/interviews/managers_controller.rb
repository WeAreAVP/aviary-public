# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # ManagerController
  class ManagersController < ApplicationController
    include XMLFileHandler
    include InterviewsHelper
    include Aviary::BulkOperation
    include Aviary::ZipperService
    before_action :authenticate_user!, except: :export

    before_action :set_interview, only: %i[show edit update destroy sync preview]

    def ohms_configuration
      authorize! :manage, Interviews::Interview
      @ohms_configuration = OhmsConfiguration.where('organization_id', current_organization.id).try(:first)
      @ohms_configuration = OhmsConfiguration.new if @ohms_configuration.nil?
    end

    def ohms_configuration_update
      authorize! :manage, Interviews::Interview
      @ohms_configuration = OhmsConfiguration.where('organization_id', current_organization.id).try(:first)
      if @ohms_configuration.nil?
        @ohms_configuration = OhmsConfiguration.new
        @ohms_configuration.organization_id = current_organization.id
      end
      @ohms_configuration.update(ohms_configuration_params)
      redirect_to ohms_configuration_url
    end

    # GET /interviews
    # GET /interviews.json
    def index
      if request.path.include?('my_ohms_assignment')
        @organization_user = OrganizationUser.find_by_user_id(current_user.id)
        user_current_organization = @organization_user.organization
        @search_columns = user_current_organization.interview_search_column
        @display_columns = user_current_organization.interview_display_column
        @collections = Collection.where(organization_id: user_current_organization.id)
        @users = user_current_organization.organization_ohms_assigned_users
      else
        authorize! :manage, Interviews::Interview
        session[:interview_bulk] = [] unless request.xhr?
        @search_columns = current_organization.interview_search_column
        @display_columns = current_organization.interview_display_column
        @collections = Collection.where(organization_id: current_organization.id)
        @organization_user = OrganizationUser.find_by user_id: current_user.id, organization_id: current_organization.id
        @users = current_organization.organization_ohms_assigned_users
      end
    end

    def listing
      authorize! :manage, Interviews::Interview unless request.path.include?('my_assignment_listing')
      if request.path.include?('my_assignment_listing')
        organization_user = if current_organization.nil?
                              OrganizationUser.find_by user_id: current_user.id
                            else
                              OrganizationUser.find_by user_id: current_user.id, organization_id: current_organization.id
                            end
        user_current_organization = organization_user.organization
        respond_to do |format|
          format.html
          format.json { render json: InterviewsDatatable.new(view_context, user_current_organization, '', organization_user, (current_organization.nil? ? false : true)) }
        end
      else
        organization_user = OrganizationUser.find_by user_id: current_user.id, organization_id: current_organization.id
        respond_to do |format|
          format.html
          format.json { render json: InterviewsDatatable.new(view_context, current_organization, '', organization_user, true) }
        end
      end
    end

    # GET /interviews/1
    # GET /interviews/1.json
    def show; end

    # GET /interviews/new
    def new
      authorize! :manage, Interviews::Interview
      @interview = Interviews::Interview.new
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('edit', @interview)
      thesaurus_settings = ::Thesaurus::ThesaurusSetting.where(organization_id: current_organization.id, is_global: true, thesaurus_type: 'record').try(:first)
      thesaurus_keys = thesaurus_settings.present? ? Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus_settings.thesaurus_keywords).sort_by(&:term) : []
      @keys = get_thesaurus_terms_as_json(thesaurus_keys)

      thesaurus_subs = thesaurus_settings.present? ? Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus_settings.thesaurus_subjects).sort_by(&:term) : []
      @subjects = get_thesaurus_terms_as_json(thesaurus_subs)
      @selected_keyword_ids = []
      @selected_subjects_ids = []
    end

    # GET /interviews/1/edit
    def edit
      authorize! :manage, current_organization
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('edit', @interview)
      thesaurus_settings = ::Thesaurus::ThesaurusSetting.where(organization_id: current_organization.id, is_global: true, thesaurus_type: 'record').try(:first)
      thesaurus_keys = thesaurus_settings.present? ? Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus_settings.thesaurus_keywords).sort_by(&:term) : []
      @keys = get_thesaurus_terms_as_json(thesaurus_keys)

      thesaurus_subs = thesaurus_settings.present? ? Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus_settings.thesaurus_subjects).sort_by(&:term) : []
      @subjects = get_thesaurus_terms_as_json(thesaurus_subs)

      selected_keyword_ids = @interview[:keywords].present? ? @interview[:keywords] : []
      selected_keyword_ids = Thesaurus::ThesaurusTerms.where(id: selected_keyword_ids)
      @selected_keyword_ids = selected_keyword_ids.present? ? get_thesaurus_terms_as_json(selected_keyword_ids) : get_thesaurus_terms_as_json(@interview[:keywords])

      selected_subjects_ids = @interview[:keywords].present? ? @interview[:subjects] : []
      selected_subjects_ids = Thesaurus::ThesaurusTerms.where(id: selected_subjects_ids)
      @selected_subjects_ids = selected_subjects_ids.present? ? get_thesaurus_terms_as_json(selected_subjects_ids) : get_thesaurus_terms_as_json(@interview[:subjects])
    end

    def preview
      authorize! :manage, Interviews::Interview
    end

    # GET /interviews/bulk_edit
    def bulk_edit; end

    def bulk_interview_edit
      if params['check_type'] == 'download_notes'
        csv_rows = export_csv(session[:interview_bulk])
        filename = "bulkexport_archivednote_#{DateTime.now.strftime('%Y%m%d')}"
        notes_csv = CSV.generate(headers: true) do |csv|
          csv_rows.map { |row| csv << row }
        end
        send_data notes_csv, filename: "#{filename}.csv", type: 'csv'

      elsif params['check_type'] == 'bulk_delete'
        Interviews::Interview.where(id: session[:interview_bulk]).each(&:destroy) if session[:interview_bulk].present?
        respond_to do |format|
          format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'mark_online'
        Interviews::Interview.where(id: session[:interview_bulk]).each do |interview|
          interview.update(record_status: 'Online')
          interview.reindex
        end
        respond_to do |format|
          format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'mark_not_restricted'
        Interviews::Interview.where(id: session[:interview_bulk]).each do |interview|
          interview.update(miscellaneous_use_restrictions: false)
          interview.reindex
        end
        respond_to do |format|
          format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'mark_restricted'
        Interviews::Interview.where(id: session[:interview_bulk]).each do |interview|
          interview.update(miscellaneous_use_restrictions: true)
          interview.reindex
        end
        respond_to do |format|
          format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'mark_ofline'
        Interviews::Interview.where(id: session[:interview_bulk]).each do |interview|
          interview.update(record_status: 'Offline')
          interview.reindex
        end
        respond_to do |format|
          format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
        end
      elsif params['check_type'] == 'ohms_assigned_users'
        if params[:assigned_users].present?
          user_id = params[:assigned_users]

          Interviews::Interview.where(id: session[:interview_bulk]).each do |interview|
            interview.update(ohms_assigned_user_id: user_id)
            interview.reindex
          end
          respond_to do |format|
            format.html { redirect_to ohms_records_path, notice: t('updated_successfully') }
          end
        else
          respond_to do |format|
            format.html { redirect_to ohms_records_path, notice: t('error_update_again') }
          end
        end
      elsif params['check_type'] == 'download_xml'
        self.tmp_user_folder = "tmp/archive_#{current_user.id}_#{Time.now.to_i}"
        dos_xml = []
        dos_xml_files = []
        FileUtils.mkdir_p(tmp_user_folder) unless Dir.exist?(tmp_user_folder)
        session[:interview_bulk].each do |single_interview|
          interview = Interviews::Interview.find_by(id: single_interview)
          if interview.present?
            export_text = Aviary::ExportOhmsInterviewXml.new.export(interview)
            doc = Nokogiri::XML(export_text.to_xml)
            error_messages = xml_validation(doc)
            unless error_messages.any?
              dos_xml << { xml: export_text.to_xml, accession_number: interview.accession_number, title: interview.title, id: interview.id, ohms_xml_filename: interview.miscellaneous_ohms_xml_filename.gsub(/\s+/, '_') }
            end
          end
        end

        if dos_xml.present?
          dos_xml.each do |single_dos_xml|
            file_name = if single_dos_xml[:ohms_xml_filename].present?
                          single_dos_xml[:ohms_xml_filename].gsub(/\s+/, '_').gsub(/.xml$/, '')
                        else
                          single_dos_xml[:accession_number].empty? ? single_dos_xml[:title] : single_dos_xml[:accession_number]
                        end + '.xml'
            File.binwrite(File.join(tmp_user_folder, file_name), single_dos_xml[:xml])
            dos_xml_files << file_name
          end
        end
        file_path = Rails.root.join("#{tmp_user_folder}.zip")
        zip_data = process_and_create_zip_file(dos_xml_files, file_path)
        send_data(zip_data, type: 'application/zip', filename: "export_xml_interview_#{Time.now.to_i}.zip", disposition: 'attachment')
      end
    end

    def sync
      if request.post? || request.patch?
        @interview.update(sync_status: params['interviews_interview']['sync_status'])
        file_transcripts_update = @interview.file_transcripts.where(interview_transcript_type: 'main').try(:first)
        main_transcript = Sanitize.fragment(params['interviews_interview']['main_transcript'].strip)
        main_transcript = main_transcript.gsub("\r", "\n").gsub("\n\n", "\n").gsub("\n \n", '').gsub("\n [", '[')
        main_transcript = fix_line_breaks(main_transcript)
        file = Tempfile.new('content')
        file.path
        file.write(main_transcript)

        transcript_manager = Aviary::OhmsTranscriptManager.new
        transcript_manager.sync_interval = params['interviews_interview']['timecode_intervals'].to_f
        transcript_manager.from_resource_file = false
        hash = transcript_manager.parse_text(main_transcript, file_transcripts_update)
        transcript_manager.map_hash_to_db(file_transcripts_update, hash, false)
        file.close
        file.unlink
        main_transcript
      end
      @data_main = []
      @data_translation = []
      @secondary_transcript = nil
      @main_transcript = nil

      @data_main = []
      @data_translation = []
      @secondary_transcript = nil
      @main_transcript = nil
      interview_file_transcript = nil
      file_transcripts_main = @interview.file_transcripts
      if file_transcripts_main.present? && file_transcripts_main.where(interview_transcript_type: 'main').try(:first).present?
        @main_transcript = file_transcripts_main.where(interview_transcript_type: 'main').try(:first)
        interview_file_transcript = @main_transcript.file_transcript_points.order('start_time asc') if @main_transcript.present?
      end

      if interview_file_transcript.present?
        interview_file_transcript.each do |single_info|
          @data_main << { id: single_info.id, text: single_info.text,
                          start_time: single_info.start_time.present? ? time_to_duration(single_info.start_time) : '00:00:00',
                          end_time: single_info.end_time.present? ? time_to_duration(single_info.end_time) : '00:00:00' }
        end
      end

      interview_transcript_translation = nil
      if file_transcripts_main.present? && file_transcripts_main.where(interview_transcript_type: 'translation').try(:first).present?
        @secondary_transcript = file_transcripts_main.where(interview_transcript_type: 'translation').try(:first)
        interview_transcript_translation = @secondary_transcript.file_transcript_points.order('start_time asc')
      end

      if interview_transcript_translation.present?
        interview_transcript_translation.each do |single_info|
          @data_translation << { id: single_info.id, text: single_info.text,
                                 start_time: single_info.start_time.present? ? time_to_duration(single_info.start_time) : '00:00:00',
                                 end_time: single_info.end_time.present? ? time_to_duration(single_info.end_time) : '00:00:00' }
        end
      end
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('show', @interview, 'sync')
      respond_to do |format|
        format.html
        format.json { render json: { response: { data_main: data_main, data_translation: data_translation } } }
      end
    end

    # GET /interviews/1/export.format
    def export
      authenticate_user! unless params[:viewer] == ENV['PREVIEW_KEY']
      authorize! :manage, Interviews::Interview unless params[:viewer] == ENV['PREVIEW_KEY']
      interview = Interviews::Interview.find(params[:id])
      export_text = Aviary::ExportOhmsInterviewXml.new.export(interview)
      doc = Nokogiri::XML(export_text.to_xml)
      error_messages = xml_validation(doc)

      if error_messages.any?
        respond_to do |format|
          format.any { redirect_to ohms_records_path, notice: 'Something went wrong. Please try again later.' }
        end
      else
        file_name = if interview.miscellaneous_ohms_xml_filename.empty?
                      interview.accession_number.empty? ? interview.title : interview.accession_number
                    else
                      interview.miscellaneous_ohms_xml_filename.gsub(/\s+/, '_').gsub(/.xml$/, '')
                    end

        respond_to do |format|
          format.xml { send_data(export_text.to_xml, filename: "#{file_name}.xml") }
          format.any { redirect_to ohms_records_path, notice: 'Not a valid URL.' }
        end
      end
    end

    # POST /interviews
    # POST /interviews.json
    def create
      authorize! :manage, Interviews::Interview
      @interview = Interviews::Interview.new(interview_params)
      @interview.organization = current_organization
      respond_to do |format|
        if @interview.save
          format.html { redirect_to ohms_records_edit_path(@interview.id), notice: 'Interview was successfully created.' }
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
      authorize! :manage, Interviews::Interview
      respond_to do |format|
        if @interview.update(interview_params)
          format.html { redirect_to ohms_records_edit_path(@interview.id), notice: 'Interview was successfully updated.' }
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
      authorize! :manage, Interviews::Interview
      @interview.destroy
      respond_to do |format|
        format.html { redirect_to ohms_records_path, notice: 'Interview was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    def update_column_info
      authorize! :manage, Interviews::Interview
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
      authorize! :manage, Interviews::Interview
      file_data = params[:importXML]
      response_body = {}
      file_data.each do |data|
        response = if data.content_type.include? 'csv'
                     Aviary::ImportOhmsInterviewCsv.new.import(data, current_organization, current_user, params[:status].to_i)
                   else
                     Aviary::ImportOhmsInterviewXml.new.import(data, current_organization, current_user, params[:status].to_i)
                   end
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

    def ohms_assignments
      user_id = params[:user_id]
      interview_id = params[:interview_id]
      interview = Interview.find(interview_id)
      authorize! :manage, interview
      full_name = ''
      user = User.where(id: user_id).try(:first)
      if user.present?
        full_name = user.full_name
      end
      msg = if interview.update(ohms_assigned_user_id: user_id, ohms_assigned_user_name: full_name)
              { success: true, message: t('updated_successfully') }
            else
              { success: false, message: t('error_update') }
            end
      respond_to do |format|
        format.html { redirect_to ohms_records_path, notice: 'Interview was successfully updated.' }
        format.json { render json: msg, status: :accepted }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_interview
      @interview = Interviews::Interview.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def interview_params
      params[:interviews_interview][:keywords] = if params[:interviews_interview][:keywords].present?
                                                   params[:interviews_interview][:keywords].split('; ')
                                                 else
                                                   []
                                                 end

      params[:interviews_interview][:subjects] = if params[:interviews_interview][:subjects].present?
                                                   params[:interviews_interview][:subjects].split('; ')
                                                 else
                                                   []
                                                 end

      params.require(:interviews_interview)
            .permit(:title, :accession_number, :interview_date, :date_non_preferred_format, :collection_id, :collection_name, :collection_link, :series_id, :series,
                    :series_link, :summary, :thesaurus_keywords, :thesaurus_subjects, :thesaurus_titles, :transcript_sync_data, :transcript_sync_data_translation,
                    :media_format, :media_host, :media_url, :media_duration, :media_filename, :media_type, :right_statement, :usage_statement, :acknowledgment,
                    :language_info, :include_language, :language_for_translation, :miscellaneous_cms_record_id, :miscellaneous_ohms_xml_filename,
                    :miscellaneous_use_restrictions, :miscellaneous_sync_url, :miscellaneous_user_notes, :interview_status, :status, :avalon_target_domain,
                    :metadata_status, :embed_code, :media_host_account_id, :media_host_player_id, :media_host_item_id,
                    interviewee: [], interviewer: [], keywords: [], subjects: [], format_info: [])
    end

    def ohms_configuration_params
      params.require(:ohms_configuration).permit(:configuration)
    end

    def get_thesaurus_terms_as_json(thesauru_terms)
      keys = []
      i = 0
      if thesauru_terms.present?
        thesauru_terms.each do |thesaurus|
          keys << {
            id: (thesaurus.try(:id).present? ? thesaurus.id : thesaurus),
            name: (thesaurus.try(:term).present? ? thesaurus.term : thesaurus)
          }
          i += 1
        end
      end
      keys.to_json
    end
  end
end
