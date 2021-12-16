# frozen_string_literal: true

# CatalogController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include BlacklightRangeLimit::ControllerOverride
  include Blacklight::Catalog
  include ApplicationHelper
  before_action :mutiple_keyword_handler, :session_param_update, :select_sort_and_view
  before_action :update_facets, except: %i[assign_to_playlist update_selected_playlist]

  def index
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    super
  end

  def update_facets
    @org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
    @resource_fields = @org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'search_sort_order')
    if current_organization.present? && @resource_fields.present?
      @resource_fields.each_with_index do |(system_name, single_collection_field), _index|
        next if !single_collection_field['search_display'].to_s.to_boolean? || single_collection_field['type'] == 'editor'
        global_status = single_collection_field['description_display'].to_s.to_boolean?
        field_conf = single_collection_field['field_configuration']
        global_status = true if field_conf.present? && field_conf['special_purpose'].present? && boolean_value(field_conf['special_purpose']) && !%w[collection_title has_transcript has_index duration access].include?(system_name)
        next if !global_status && !%w[collection_title has_transcript has_index duration access].include?(system_name)
        if system_name == 'collection_title'
          @blacklight_config.add_facet_field('collection_id_is', Organization.field_list_with_options[:collection_id_is])
          next
        end
        if system_name == 'duration'
          @blacklight_config.add_facet_field('description_duration_ls', Organization.field_list_with_options[:description_duration_ls])
          next
        end

        if system_name == 'access'
          @blacklight_config.add_facet_field('access_ss', Organization.field_list_with_options[:access_ss])
          next
        end
        if system_name == 'has_transcript'
          @blacklight_config.add_facet_field('has_transcript_ss', Organization.field_list_with_options[:has_transcript_ss])
          next
        end
        if system_name == 'has_index'
          @blacklight_config.add_facet_field('has_index_ss', Organization.field_list_with_options[:has_index_ss])
          next
        end
        if single_collection_field['is_default'].to_s.to_boolean?

          default_field_info = Organization.field_list_with_options[system_name.to_sym]
          next unless default_field_info.present?
          field_settings = default_field_info.slice(:label, :single, :helper_method, :tag, :ex, :partial, :range)

          @blacklight_config.add_facet_field(default_field_info[:key], field_settings)
        else
          solr_search_management = SolrSearchManagement.new
          solr_filed = Aviary::SolrIndexer.define_custom_field_system_name(system_name.to_s, single_collection_field['type'].to_s, true)
          range_start = "['' TO *]"
          range_start = '[0 TO *]' if single_collection_field['type'].to_s == 'date'
          response = begin
                       solr_search_management.select_query(q: '*:*', fq: ['document_type_ss:collection_resource', "#{solr_filed}:#{range_start}"], fl: 'id_is', rows: 1)
                     rescue StandardError => e
                       puts e
                       false
                     end
          field_info = { label: single_collection_field['label'], single: false }
          if single_collection_field['type'].to_s == 'date'
            field_info = { label: single_collection_field['label'], single: true, partial: 'blacklight_range_limit/range_limit_panel', range: { segments: false }, tag: "#{solr_filed}-tag", ex: "#{solr_filed}-tag" }
          end

          @blacklight_config.add_facet_field(solr_filed.to_s, field_info) if response.present? && response['response'].present? && response['response']['numFound'] > 0
        end
      end
    else
      Organization.field_list_with_options.each do |_index, single_field|
        if single_field[:key] == 'description_duration_ls' || single_field[:key] == 'description_date_search_lms'
          @blacklight_config.add_facet_field(single_field[:key].to_s, label: single_field[:label], single: single_field[:single], helper_method: single_field[:helper_method], tag: single_field[:tag],
                                                                      ex: single_field[:ex], partial: 'blacklight_range_limit/range_limit_panel', range: { segments: false })
        else
          @blacklight_config.add_facet_field(single_field[:key].to_s, label: single_field[:label], single: single_field[:single], helper_method: single_field[:helper_method], tag: single_field[:tag], ex: single_field[:ex])
        end
      end
    end
    flag_param_changed = false
    unless request.fullpath.include?('update_selected_playlist') || request.fullpath.include?('assign_to_playlist')
      facet_lists = %w[f keywords title_text resource_description indexes transcript collection_title op description_duration_ls description_date_search_lms]
      session[:old_facets] = {} unless session[:old_facets].present?
      facet_lists.each do |single_facet|
        unless session[:old_facets][single_facet] == params[single_facet]
          flag_param_changed = true
        end
        session[:old_facets][single_facet] = params[single_facet]
      end
    end
    session[:search_playlist_id] = {} if flag_param_changed
    session[:search_facets] = {}
    session[:search_facets]['all'] ||= {}
    session[:search_facets]['range'] ||= {}
    if params.key?('reset_facets')
      session[:search_facets] = {}
    else
      session[:search_facets]['range'] = params[:range] if params.key?(:range)
      session[:search_facets]['all'] = params[:f] if params.key?(:f)
    end
  end

  def assign_to_playlist
    if session[:search_playlist_id].present?
      session[:search_playlist_id].to_a.flatten.uniq!.each do |single_resource_ids|
        PlaylistPresenter.add_resource_to_playlist(single_resource_ids, Playlist.find(params[:select_playlist]), current_user)
      end
    end
    session[:search_playlist_id] = {}
    respond_to do |format|
      format.json { render json: 'Resources Successfully added to playlist', notice: 'Resources Successfully added to playlist.', status: :accepted }
    end
  rescue StandardError => e
    Rails.logger.error e
    session[:search_playlist_id] = {}
    respond_to do |format|
      format.json { render json: t('error_update_again'), status: :unprocessable_entity }
    end
  end

  def update_selected_playlist
    session[:search_playlist_id] = {} if params['type'] == 'bulk'
    if params[:playlist_resource_id].present?
      params[:playlist_resource_id].each do |single_id|
        if params[:status].to_boolean?
          session[:search_playlist_id][single_id.to_s] = single_id
        else
          session[:search_playlist_id].delete(single_id.to_s)
        end
      end
    end
    respond_to do |format|
      format.json { render json: session[:search_playlist_id].size, status: :accepted }
    end
  end

  def mutiple_keyword_handler
    session[:searched_for_org] = current_organization.present?
    current_params_index_raw = ''
    session[:searched_keywords] ||= {}
    unless params.key?('reset_facets')
      session[:searched_keywords] = {} if session[:searched_keywords].size <= 0 || (params.key?('update_advance_search') && params['update_advance_search'] == 'update_advance_search') ||
                                          params['search_field'] != 'advanced' || (params['search_type'] == 'simple' && !params.key?('range'))
    end
    return if !params.key?('op') || params['search_field'] != 'advanced'
    params['op'].each_with_index do |single_operator, key|
      has_value = false
      current_params = { 'search_field' => 'advanced', 'commit' => 'Search', 'op' => single_operator, 'type_of_search' => params['type_of_search'][key], 'request_is_xhr' => request.xhr? }
      SearchBuilder.facets_list.each do |single_facet|
        if params[single_facet.to_s].present? && params[single_facet.to_s][key].present?
          has_value = true
          current_params_index_raw += params[single_facet.to_s][key] + single_operator + single_facet.to_s
          current_params[single_facet.to_s] = params[single_facet.to_s][key]
          current_params['keyword_searched'] = params[single_facet.to_s][key]
        end
      end
      current_params_index = OpenSSL::Digest::SHA256.new.hexdigest(current_params_index_raw).strip
      if has_value
        session[:searched_keywords][current_params_index] = nil unless session[:searched_keywords].key?(current_params_index)
        session[:searched_keywords][current_params_index] = current_params if current_params_index.present?
      end
    end
  end

  def session_param_update
    return if request.fullpath.include?('update_selected_playlist')
    current_uri_params = request.fullpath
    begin
      if current_uri_params.include?('/catalog.json')
        current_uri_params['/catalog.json'] = ''
      elsif current_uri_params.include?('/catalog?')
        current_uri_params['/catalog?'] = ''
      end
    rescue StandardError => e
      Rails.logger.error e
    end
    current_uri_params = current_uri_params.gsub('update_advance_search=update_advance_search', '')
    session[:solr_params] = current_uri_params
    record_last_bread_crumb("/catalog?#{current_uri_params}", 'Back to Search')
  end

  def select_sort_and_view
    session[:selected_sort_key] = params[:sort] if params.key?(:sort)
    session[:selected_search_result_view] = params[:view] if params.key?(:view)
    if params[:start_over_search]
      session[:selected_sort_key] = nil
      session[:selected_search_result_view] = nil
    end
    @selected_sort_key = session[:selected_sort_key]
    params[:view] = session[:selected_search_result_view]
  end

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search[:form_solr_parameters] ||= {}
    config.http_method = :post
    config.default_per_page = 12
    # Search Fields Dropdown
    config.add_search_field('keywords') do |field|
      field.label = 'Any Field'
      field.solr_local_parameters = {
        qf: 'keywords',
        pf: 'keywords'
      }
    end

    config.add_search_field('title_text') do |field|
      field.label = 'Resource Name'
      field.solr_local_parameters = {
        qf: 'title_text',
        pf: 'title_text'
      }
    end

    config.add_search_field('resource_description') do |field|
      field.label = 'Resource Description'
      field.solr_local_parameters = {
        qf: SearchBuilder.description_search_fields.join(' '),
        pf: SearchBuilder.description_search_fields.join(' ')
      }
    end

    config.add_search_field('indexes') do |field|
      field.label = 'Indexes'
      field.solr_local_parameters = {
        qf: SearchBuilder.index_search_fields.join(' '),
        pf: SearchBuilder.index_search_fields.join(' ')
      }
    end

    config.add_search_field('transcript') do |field|
      field.label = 'Transcript'
      field.solr_local_parameters = {
        qf: SearchBuilder.transcript_search_fields.join(' '),
        pf: SearchBuilder.transcript_search_fields.join(' ')
      }
    end

    config.add_search_field('collection_title') do |field|
      field.label = 'Collection Title'
      field.solr_local_parameters = {
        qf: 'collection_title',
        pf: 'collection_title'
      }
    end

    config.add_sort_field 'score asc', label: 'Relevance'
    config.add_sort_field 'title_ss desc', label: 'Title (Z-A)'
    config.add_sort_field 'title_ss asc', label: 'Title (A-Z)'
    config.add_sort_field 'created_at_ds desc', label: 'Date Added'

    config.view.grid.partials = %i[index_header index]
    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: false)
    config.add_facet_fields_to_solr_request!
    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end
end
