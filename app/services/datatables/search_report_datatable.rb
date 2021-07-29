# SyncProgressDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SearchReportDatatable < ApplicationDatatable
  delegate :params, :search_catalog_path, to: :@view

  def initialize(view, current_organization, type)
    @view = view
    @current_organization = current_organization
    @type = type
  end

  private

  def data
    search_tracking, count_records = fetch_search_terms
    data = search_tracking.map do |progress|
      [].tap do |column|
        params_custom_first = '&title_text[]=&resource_description[]=&indexes[]=&transcript[]=&op[]=&type_of_search[]=simple'
        params_custom = '?utf8=✓&search_type=simple&search_field=advanced&commit=Search&type_of_field_selector_single=keywords&keywords[]=' + progress.search_keyword + params_custom_first
        link = "<a target='_blank' href='#{search_catalog_path + params_custom}'>#{progress.search_keyword}</a>"
        column << link
        column << progress.time.to_date
        column << progress.search_count
      end
    end
    [data, count_records]
  end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_search_terms
    search_tracking, count = SearchTracking.fetch_search_terms(page, per_page, sort_column, sort_direction, @current_organization.id, params, type: @type, export: false)
    [search_tracking, count]
  end

  def columns
    %w(search_keyword MAX(ahoy_events.time) count(search_trackings.id))
  end
end
