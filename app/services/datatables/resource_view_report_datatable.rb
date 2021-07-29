# ResourceViewReportDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ResourceViewReportDatatable < ApplicationDatatable
  delegate :params, :collection_collection_resource_path, to: :@view

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    resource_views, count_records = fetch_resource_views
    data = resource_views.map do |progress|
      [].tap do |column|
        column << progress.id
        column << "<a target='_blank' href='#{collection_collection_resource_path(progress.collection_id, progress.id)}'> #{progress.title}</a>"
        column << progress.time.to_date
        column << progress.view_count
      end
    end
    [data, count_records]
  end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_resource_views
    resource_views, count = AnalyticsReports.fetch_resource_view(page, per_page, sort_column, sort_direction, @current_organization.id, params)
    [resource_views, count]
  end

  def columns
    %w(collection_resources.id collection_resources.title MAX(ahoy_events.time) count(ahoy_events.id))
  end
end
