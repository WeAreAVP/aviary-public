# CollectionResourcePresenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CollectionResourcePresenter < BasePresenter
  delegate :list_resources_collection_path, :collection_collection_resource_path, :collection_collection_resource_add_resource_file_path, :session, :edit_collection_collection_resource_path, :add_breadcrumb, to: :h
  include ApplicationHelper
  include DetailPageHelper

  def self.stopwords
    %w(a an and are as at be but by for if in into is it no not of on or such that the their then there these they this to was will with)
  end

  def breadcrumb_manager(type, collection_resource, collection)
    active_link = 'class="active" href="javascript:void(0);" aria-current="page"'
    collection_link = "<a href='#{list_resources_collection_path(collection)}'>Collection</a>".html_safe
    resource_link = "<a href='#{collection_collection_resource_path(collection, collection_resource)}'>Resource Detail</a>".html_safe
    manage_file_link = "<a href='#{collection_collection_resource_add_resource_file_path(collection, collection_resource)}'>Manage Media Files</a>".html_safe
    edit_link = "<a href='#{edit_collection_collection_resource_path(collection, collection_resource)}'>General Settings</a>".html_safe
    case type
    when 'edit'
      add_breadcrumb collection_link
      add_breadcrumb "<a #{active_link}>General Settings</a>".html_safe
      add_breadcrumb manage_file_link
      add_breadcrumb resource_link
    when 'show'
      add_breadcrumb collection_link
      add_breadcrumb edit_link
      add_breadcrumb manage_file_link
      add_breadcrumb "<a #{active_link}'>Resource Detail</a>".html_safe
    when 'manage_file'
      add_breadcrumb collection_link
      add_breadcrumb edit_link
      add_breadcrumb "<a #{active_link}>Manage Media Files</a>".html_safe
      add_breadcrumb resource_link
    end
  end

  def selected_index_transcript(resource_file, selected_index, selected_transcript)
    begin
      file_indexes = resource_file.file_indexes.order_index
    rescue StandardError => ex
      file_indexes = {}
      puts ex.backtrace.join("\n")
    end
    begin
      file_transcripts = resource_file.file_transcripts.order_transcript
    rescue StandardError => ex
      file_transcripts = {}
      puts ex.backtrace.join("\n")
    end
    begin
      selected_index = file_indexes.try(:first).try(:id) if selected_index.blank? || selected_index.to_i <= 0
    rescue StandardError => ex
      selected_index = 0
      puts ex.backtrace.join("\n")
    end
    begin
      selected_transcript = file_transcripts.try(:first).try(:id) if selected_transcript.blank? || selected_transcript.to_i <= 0
    rescue StandardError => ex
      selected_transcript = 0
      puts ex.backtrace.join("\n")
    end
    [file_indexes, file_transcripts, selected_index, selected_transcript]
  end

  def all_params_information(params)
    session_video_text_all = {}
    return session_video_text_all unless params['keywords'].present?
    keywords = params['keywords'].class == ActionController::Parameters ? params['keywords'].to_enum.to_h.values : params['keywords']
    keywords = keywords.try(:length).present? ? keywords.sort_by(&:length).reverse : []
    keywords = keywords.map { |keyword| SearchBuilder.remove_illegal_characters(keyword, 'advance').delete('"') } if keywords.present?
    if keywords.present?
      keywords.each do |single_quotes|
        key = key_hash_manager(single_quotes)
        session_video_text_all[key] = single_quotes if single_quotes.present?
      end
    end
    session_video_text_all
  end

  def generate_params_for_detail_page(resource_file, collection_resource, session, params)
    params[:collection_resource_id] = collection_resource.id if params[:collection_resource_id].present?
    session_video_text_all = all_params_information(params)

    selected_transcript = {}
    selected_index = {}
    unless resource_file.nil?
      selected_transcript = session[:search_text]["selected_transcript_#{params[:collection_resource_id]}"][resource_file.id.to_s] if session.key?(:search_text) &&
                                                                                                                                      session[:search_text].key?("selected_transcript_#{collection_resource.id}") &&
                                                                                                                                      session[:search_text]["selected_transcript_#{params[:collection_resource_id]}"].key?(resource_file.id.to_s)

      selected_index = session[:search_text]["selected_index_#{params[:collection_resource_id]}"][resource_file.id.to_s] if session.key?(:search_text) &&
                                                                                                                            session[:search_text].key?("selected_index_#{collection_resource.id}") &&
                                                                                                                            session[:search_text]["selected_index_#{params[:collection_resource_id]}"].key?(resource_file.id.to_s)
    end
    session[:view_type] = params[:view_type] if params[:view_type].present? && %w(detail annotation).include?(params[:view_type])
    count_file_wise = {}
    [session_video_text_all, selected_transcript, selected_index, count_file_wise]
  end

  def transcript_point_list(file_transcript, file_transcript_points, session_video_text_all, can_access_annotation, all_annotations)
    recorded = []
    recorded[file_transcript.id] ||= []
    listing_transcripts = {}
    transcript_count = {}
    annotation_search_count = {}
    transcript_time_wise = {}
    annotation_count = {}
    annotation_set_present_flag = file_transcript.annotation_set.present?
    counter_listing = 0
    global_counter_listing = 0

    file_transcript_points.each_with_index do |transcript_point, counter|
      present(transcript_point) do |presenter|
        transcript_time_start_single = !recorded[file_transcript.id].include?(transcript_point.start_time.to_i) ? "transcript_time_start_#{transcript_point.start_time.to_i}" : ''
        transcript_time_wise = h.transcript_page_wise_time_range(transcript_time_wise, transcript_point, counter)
        transcript_count, annotation_search_count = h.count_occurrence(transcript_point, session_video_text_all, transcript_count, 'transcript', false, counter, annotation_search_count, all_annotations)
        listing_transcripts[counter_listing] ||= ''
        listing_transcripts[counter_listing] += presenter.show_transcript_point(transcript_time_start_single, can_access_annotation, annotation_search_count, session_video_text_all)
      end
      global_counter_listing += 1
      if global_counter_listing > 110
        counter_listing += 1
        global_counter_listing = 0
      end
      recorded[file_transcript.id] << transcript_point.start_time.to_i
    end

    annotation_count = DetailPageHelper.count_annotation_occurrence(file_transcript.id, annotation_count) if annotation_set_present_flag
    other_file_transcripts = file_transcript.collection_resource_file.file_transcripts.includes([:file_transcript_points]).where.not(id: file_transcript.id)
    if other_file_transcripts.present?
      other_file_transcripts.each do |single_file_transcript|
        single_file_transcript.file_transcript_points.each_with_index do |transcript_point, counter|
          transcript_time_wise = transcript_page_wise_time_range(transcript_time_wise, transcript_point, counter)
          transcript_count, annotation_search_count = count_occurrence(transcript_point, session_video_text_all, transcript_count, 'transcript', false, counter, annotation_search_count, all_annotations)
        end
      end
    end
    [listing_transcripts, transcript_count, transcript_time_wise, annotation_count, annotation_search_count]
  end

  def file_wise_count(collection_resource, count_file_wise, session_video_text_all)
    counts_media_metadata = {}

    collection_resource.collection_resource_files.includes(%i[file_indexes file_transcripts]).each do |single_file|
      count_file_wise[single_file.id] ||= {}
      single_file.file_indexes.includes([:file_index_points]).each do |single_index|
        single_index.file_index_points.each do |index_point|
          count_file_wise = h.count_occurrence(index_point, session_video_text_all, count_file_wise, 'index', true)
        end
      end
      annotation_point_sum = 0
      single_file.file_transcripts.includes([:file_transcript_points]).each do |single_transcripts|
        sorted_annotations = {}
        single_transcripts.file_transcript_points.each do |transcript_point|
          count_file_wise, _annotation_search_count = h.count_occurrence(transcript_point, session_video_text_all, count_file_wise, 'transcript', true, nil, nil, sorted_annotations)
        end
        if single_transcripts.annotation_set.try(:annotations).present?
          single_transcripts.annotation_set.annotations.each do |single_annotation|
            session_video_text_all.each do |_, single_keyword|
              annotation_point_sum += count_em(single_annotation.body_content, single_keyword)
            end
          end
        end
      end
      begin
        count_file_wise[single_file.id]['total-transcript'] += annotation_point_sum
      rescue StandardError
        count_file_wise[single_file.id]['total-transcript'] ||= 0
      end

      counts_media_metadata[single_file.id] ||= {}
    end
    [count_file_wise, counts_media_metadata]
  end
end
