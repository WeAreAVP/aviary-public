# IndexesViewReportDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::RssPodcastReportDatatable < Datatables::ApplicationDatatable
  delegate :params, to: :@view

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    resource_views, count_records = fetch_indexes_view
    data = resource_views.map do |progress|
      [].tap do |column|
        column << progress.title
        column << progress.podcast_title
        column << progress.view_count
      end
    end
    [data, count_records]
  end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_indexes_view
    resource_views, count = AnalyticsReportsExtended.fetch_rss_podcast_download(page, per_page, sort_column, sort_direction, @current_organization.id, params)
    [resource_views, count]
  end

  def columns
    # progress.feed_id
    %w(collection_resources.title feeds.podcast_title count(ahoy_events.id))
  end
end
