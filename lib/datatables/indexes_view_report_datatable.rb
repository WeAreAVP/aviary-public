# IndexesViewReportDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::IndexesViewReportDatatable < Datatables::ApplicationDatatable
  delegate :params, :collection_collection_resource_details_path, to: :@view

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    resource_views, count_records = fetch_indexes_view
    data = resource_views.map do |progress|
      subdomain_handler = Utilities::AviaryDomainHandler.subdomain_handler(@current_organization)
      [].tap do |column|
        column << progress.id
        column << "<a target='_blank' href='#{collection_collection_resource_details_path(collection_id: progress.collection_id,
                                                                                          collection_resource_id: progress.collection_resource_id,
                                                                                          host: subdomain_handler)}'> #{progress.title}</a>"
        column << progress.time.to_date
        column << progress.view_count
      end
    end
    [data, count_records]
  end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_indexes_view
    resource_views, count = AnalyticsReports.fetch_indexes_view(page, per_page, sort_column, sort_direction, @current_organization.id, params)
    [resource_views, count]
  end

  def columns
    %w(file_indexes.id file_indexes.title MAX(ahoy_events.time) count(ahoy_events.id))
  end
end
