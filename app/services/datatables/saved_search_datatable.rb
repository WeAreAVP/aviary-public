# SavedSearchDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SavedSearchDatatable < ApplicationDatatable
  delegate :date_time_format, :current_user, :edit_saved_search_url, :saved_search_url, to: :@view
  attr_accessor :current_user_details

  def initialize(view)
    @view = view
  end

  private

  def data
    all_saved_searches, saved_searches_count = fetch_data
    if all_saved_searches.present?
      saved_searches_data = all_saved_searches.map do |saved_search|
        [].tap do |column|
          column << saved_search.id
          column << saved_search.title
          column << saved_search.note
          column << saved_search.organization

          column << date_time_format(saved_search.created_at)
          column << date_time_format(saved_search.updated_at)

          links = link_to 'Edit', edit_saved_search_url(id: saved_search.id), class: 'btn-sm btn-success access-edit ', remote: true
          links += link_to 'Delete', saved_search_url(id: saved_search.id), method: :delete, class: 'btn-sm btn-danger access-delete ml-1', remote: true, data: { confirm: 'Are you sure?' }
          links += link_to 'View Search Results', saved_search.url, class: 'btn-sm btn-default access-view-resource ml-1', target: '_blank', data: { id: saved_search.id }
          column << links
        end
      end
    end
    saved_searches_data ||= [] # saved_searches_data must be an array. otherwise it will throw an error on the frontend.
    [saved_searches_data, saved_searches_count]
  end

  def count; end

  def fetch_saved_resources
    fetch_data
  end

  def fetch_data
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    SavedSearch.fetch_data(page, per_page, sort_column, sort_direction, current_user, params)
  end

  def columns
    %w(id title note organization created_at updated_at url)
  end
end
