# CollectionResourcePresenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
class CollectionResourcePresenter < BasePresenter
  delegate :collection_collection_resource_path, :collection_collection_resource_add_resource_file_path, :edit_collection_collection_resource_path, :add_breadcrumb, to: :h
  include ApplicationHelper
  include DetailPageHelper

  def self.stopwords
    %w(a an and are as at be but by for if in into is it no not of on or such that the their then there these they this to was will with)
  end

  def breadcrumb_manager(type, collection_resource, collection)
    active_link = 'class="active" href="javascript:void(0);"'
    resource_link = "<a href='#{collection_collection_resource_path(collection, collection_resource)}'>Resource Detail</a>".html_safe
    manage_file_link = "<a href='#{collection_collection_resource_add_resource_file_path(collection, collection_resource)}'>Manage Media Files</a>".html_safe
    edit_link = "<a href='#{edit_collection_collection_resource_path(collection, collection_resource)}'>General Settings</a>".html_safe
    case type
    when 'edit'
      add_breadcrumb "<a #{active_link}>General Settings</a>".html_safe
      add_breadcrumb manage_file_link
      add_breadcrumb resource_link
    when 'show'
      add_breadcrumb edit_link
      add_breadcrumb manage_file_link
      add_breadcrumb "<a #{active_link}'>Resource Detail</a>".html_safe
    when 'manage_file'
      add_breadcrumb edit_link
      add_breadcrumb "<a #{active_link}>Manage Media Files</a>".html_safe
      add_breadcrumb resource_link
    end
  end

  def selected_index_transcript
    begin
      @file_indexes = @resource_file.file_indexes.order_index
    rescue StandardError => ex
      puts ex.backtrace.join("\n")
    end
    begin
      @file_transcripts = @resource_file.file_transcripts.order_transcript
    rescue StandardError => ex
      puts ex.backtrace.join("\n")
    end
    begin
      @selected_index = @file_indexes.order_index.first.id if @selected_index.blank? || @selected_index.to_i <= 0
    rescue StandardError => ex
      @selected_index = 0
      puts ex.backtrace.join("\n")
    end
    begin
      @selected_transcript = @file_transcripts.order_transcript.first.id if @selected_transcript.blank? || @selected_transcript.to_i <= 0
    rescue StandardError => ex
      @selected_transcript = 0
      puts ex.backtrace.join("\n")
    end
  end

  def generate_params_for_detail_page(resource_file, collection_resource, session, params)
    params[:collection_resource_id] = collection_resource.id if params[:collection_resource_id].present?
    session_video_text_all = if session.key?(:search_text) && session[:search_text].key?("search_text_#{collection_resource.id}")
                               session[:search_text]["search_text_#{collection_resource.id}"]
                             elsif session.key?(:searched_keywords) && !session[:searched_keywords].empty? && !session[:solr_params].blank?
                               session[:search_text]["search_text_#{collection_resource.id}"] = AdvanceSearchHelper.advance_search_query_only(session[:searched_keywords], true, session['solr_params'], stopwords)
                             else
                               ''
                             end
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
    collection_resource.collection_resource_files.includes(%i[file_indexes file_transcripts]).each do |single_file|
      count_file_wise[single_file.id] ||= {}
      single_file.file_indexes.each do |single_index|
        single_index.file_index_points.each do |index_point|
          count_file_wise = h.count_occurrence(index_point, session_video_text_all, count_file_wise, 'index', true)
        end
      end
      single_file.file_transcripts.each do |single_transcripts|
        single_transcripts.file_transcript_points.each do |transcript_point|
          count_file_wise = h.count_occurrence(transcript_point, session_video_text_all, count_file_wise, 'transcript', true)
        end
      end
    end

    [session_video_text_all, selected_transcript, selected_index, count_file_wise]
  end
end
