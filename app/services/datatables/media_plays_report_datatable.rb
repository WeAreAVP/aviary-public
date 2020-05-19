# IndexesViewReportDatatable
class MediaPlaysReportDatatable < ApplicationDatatable
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
    resource_views, count = AnalyticsReports.fetch_media_plays(page, per_page, sort_column, sort_direction, @current_organization.id, params)
    [resource_views, count]
  end

  def columns
    %w(collection_resource_files.id collection_resource_files.file_display_name MAX(ahoy_events.time) count(ahoy_events.id))
  end
end
