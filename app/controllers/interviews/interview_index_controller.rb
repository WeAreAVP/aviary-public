# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # NoteController
  class InterviewIndexController < ApplicationController
    before_action :authenticate_user!
    include ApplicationHelper
    include InterviewIndexHelper
    # GET /interview_index
    # GET /interview_index
    def show
      authorize! :manage, Interviews::Interview
      @interview = Interview.find(params[:id])
      @file_index_point = FileIndexPoint.where(file_index_id: @interview.file_indexes&.first&.id)
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('show', @interview, 'index')
    end

    def new
      authorize! :manage, Interviews::Interview
      @interview = Interview.find(params[:id])
      @file_index_point = FileIndexPoint.new
      set_thesaurus
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('edit', @interview, 'index')
    end

    def set_thesaurus
      thesaurus_settings = ::Thesaurus::ThesaurusSetting.where(organization_id: current_organization.id, is_global: true, thesaurus_type: 'index').try(:first)
      if Thesaurus::Thesaurus.where(id: @interview.thesaurus_keywords).length.zero?
        if thesaurus_settings.present?
          @interview.thesaurus_keywords = thesaurus_settings.thesaurus_keywords
        end
      elsif Thesaurus::Thesaurus.where(id: @interview.thesaurus_subjects).length.zero?
        if thesaurus_settings.present?
          @interview.thesaurus_subjects = thesaurus_settings.thesaurus_subjects
        end
      end
    end

    def edit
      authorize! :manage, Interviews::Interview
      @file_index_point = FileIndexPoint.find(params[:id])
      @file_index = FileIndex.find(@file_index_point.file_index_id)
      @interview = Interview.find(@file_index.interview_id)
      set_thesaurus
      OhmsBreadcrumbPresenter.new(@interview, view_context).breadcrumb_manager('edit', @interview, 'index')
      return unless @interview.include_language
      file_index_alt = FileIndex.find_by(interview_id: @interview.id, language: interview_lang_info(@interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
      @file_index_point_alt = []
      @file_index_point_alt = FileIndexPoint.where(file_index_id: file_index_alt.id).where(start_time: @file_index_point.start_time.to_f).where.not(id: params[:id]) if file_index_alt.present?
      return unless @file_index_point_alt.length.positive?
      @file_index_point_alt = @file_index_point_alt.first
      @file_index_point.title_alt = @file_index_point_alt.title
      @file_index_point.partial_script_alt = @file_index_point_alt.partial_script
      @file_index_point.keywords_alt = @file_index_point_alt.keywords
      @file_index_point.subjects_alt = @file_index_point_alt.subjects
      @file_index_point.synopsis_alt = @file_index_point_alt.synopsis
      @file_index_point.gps_latitude_alt = @file_index_point_alt.gps_latitude
      @file_index_point.gps_description_alt = @file_index_point_alt.gps_description
      @file_index_point.zoom_alt = @file_index_point_alt.gps_zoom
      @file_index_point.hyperlink_alt = @file_index_point_alt.hyperlink
      @file_index_point.hyperlinks_alt = @file_index_point_alt.hyperlinks
      @file_index_point.gps_points_alt = @file_index_point_alt.gps_points
      @file_index_point.id_alt = @file_index_point_alt.id
      @file_index_point.hyperlink_description_alt = @file_index_point_alt.hyperlink_description
    end

    def update
      authorize! :manage, Interviews::Interview
      @file_index_point = FileIndexPoint.find(params[:id])
      @file_index_point.update(file_index_point_params)
      start_time = human_to_seconds(params[:file_index_point][:start_time])
      @file_index_point.start_time = start_time.to_f
      @file_index_point = set_custom_values(@file_index_point, '', params)
      @file_index = FileIndex.find(@file_index_point.file_index_id)
      @interview = Interview.find(@file_index.interview_id)
      respond_to do |format|
        if @file_index_point.save
          if params[:file_index_point][:language].length > 1
            @file_index_point_alt = FileIndexPoint.find_by(id: params[:file_index_point][:id_alt])
            if @file_index_point_alt.nil?
              @file_index_point_alt = FileIndexPoint.new
              file_index_alt = FileIndex.find_or_create_by(interview_id: @interview.id, language: interview_lang_info(@interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
              if file_index_alt.id.nil?
                file_index_alt.title = ''
                file_index_alt.save(validate: false)
              end
              @file_index_point_alt.file_index_id = file_index_alt.id
            end
            @file_index_point_alt.update(file_index_point_params_alt.transform_keys { |key| key.gsub('_alt', '') })
            @file_index_point_alt.start_time = start_time.to_f
            @file_index_point_alt = set_custom_values(@file_index_point_alt, '_alt', params)
            if @file_index_point_alt.save
              start_time = params[:current_time].to_f if params[:current_time].present?
              format.html { redirect_to "#{ohms_index_path(@file_index.interview_id)}?time=#{start_time}", notice: 'Ohms Index was successfully updated.' }
              format.json { render :show, status: :created, location: @file_index }
            else
              format.html { render :new }
              format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
            end
          else
            start_time = params[:current_time].to_f if params[:current_time].present?
            format.html { redirect_to "#{ohms_index_path(@file_index.interview_id)}?time=#{start_time}", notice: 'Ohms Index was successfully updated.' }
            format.json { render :show, status: :created, location: @file_index }
          end
        else
          format.html { render :new }
          format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize! :manage, Interviews::Interview
      file_index_point = FileIndexPoint.find(params[:id])
      file_index = FileIndex.find(file_index_point.file_index_id)
      interview = Interview.find(file_index.interview_id)
      update_end_time(file_index_point)
      if interview.include_language
        file_index_alt = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
        file_index_point_alt = FileIndexPoint.where(file_index_id: file_index_alt.id).where(start_time: file_index_point.start_time.to_f).where.not(id: params[:id])
        update_end_time(file_index_point_alt.first) if file_index_point_alt.length.positive?
      end
      file_index = FileIndex.find(file_index_point.file_index_id)
      respond_to do |format|
        format.html { redirect_to ohms_index_path(file_index.interview_id), notice: 'The interview index you selected has been deleted successfully.' }
      end
    end

    def create
      authorize! :manage, Interviews::Interview
      @interview = Interview.find(params[:file_index_point][:interview_id])
      @file_index = FileIndex.find_by(interview_id: file_index_params[:interview_id], language: params[:file_index_point][:language].first)
      @file_index = FileIndex.new(file_index_params) if @file_index.nil?
      @file_index.language = params[:file_index_point][:language].first
      @file_index.user_id = current_user.id
      @file_index.save(validate: false)

      @file_index_point = FileIndexPoint.new(file_index_point_params)
      @file_index_point.file_index_id = @file_index.id
      start_time = human_to_seconds(params[:file_index_point][:start_time])
      @file_index_point.start_time = start_time.to_f
      @file_index_point = set_custom_values(@file_index_point, '', params)
      respond_to do |format|
        if @file_index_point.save
          if params[:file_index_point][:language].length > 1
            @file_index_alt = FileIndex.find_by(interview_id: file_index_params[:interview_id], language: params[:file_index_point][:language].second)
            @file_index_alt = FileIndex.new(file_index_params) if @file_index_alt.nil?
            @file_index_alt.language = params[:file_index_point][:language].second
            @file_index_alt.user_id = current_user.id
            @file_index_alt.save(validate: false)
            @file_index_point_alt = FileIndexPoint.new(file_index_point_params_alt.transform_keys { |key| key.gsub('_alt', '') })
            @file_index_point_alt.file_index_id = @file_index_alt.id
            @file_index_point_alt.start_time = start_time.to_f
            @file_index_point_alt = set_custom_values(@file_index_point_alt, '_alt', params)
            if @file_index_point_alt.save
              start_time = params[:current_time].to_f if params[:current_time].present?
              format.html { redirect_to "#{ohms_records_path(@file_index.interview_id)}?time=#{start_time}", notice: 'Interview Index was successfully created.' }
              format.json { render :show, status: :created, location: @file_index_point }
            else
              format.html { render :new }
              format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
            end

          else
            start_time = params[:current_time].to_f if params[:current_time].present?
            format.html { redirect_to "#{ohms_index_path(@file_index.interview_id)}?time=#{start_time}", notice: 'Interview Index was successfully created.' }
            format.json { render :show, status: :created, location: @file_index_point }
          end

        else
          format.html { render :new }
          format.json { render json: @file_index_point.errors, status: :unprocessable_entity }
        end
      end
    end

    def status_update
      authorize! :manage, Interviews::Interview
      interview = Interview.find(params[:id])
      interview.index_status = params[:index_status].to_i
      interview.save
      interview.reindex
      respond_to do |format|
        format.html { render :show }
        format.json { render json: {} }
      end
    end

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def file_index_params
      params.require(:file_index_point).permit(:interview_id, :title, :language)
    end

    def file_index_point_params
      params.require(:file_index_point).permit(:id, :start_time, :title, :synopsis, :partial_script, :keywords, :subjects, :gps_latitude, :gps_zoom, :gps_description, :gps_points, :hyperlinks)
    end

    def file_index_point_params_alt
      params.require(:file_index_point).permit(:id_alt, :start_time, :title_alt, :synopsis_alt, :partial_script_alt, :keywords_alt, :subjects_alt, :gps_latitude_alt, :gps_zoom_alt, :gps_description_alt, :gps_points_alt, :hyperlinks_alt)
    end
  end
end
