# SyncReportsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SyncReportsDatatable < ApplicationDatatable
  include ActionView::Helpers::UrlHelper
  def initialize(view, sync_source)
    @view = view
    @sync_source = sync_source
  end

  private

  def data
    all_progress, progress_count = fetch_progress
    progress_data = all_progress.map do |progress|
      button = "<a class=\"btn-sm btn-default\" href=\"/sync_sources/#{@sync_source.id}/download_report/#{progress.id}\">Download</a>"
      [].tap do |column|
        column << ''
        column << progress.created_at.strftime('%F %T')
        column << button
      end
    end
    if @sync_source.report.nil?
      [progress_data, progress_count]
    else
      button = "<a class=\"btn-sm btn-default\" href=\"/sync_sources/#{@sync_source.id}/download_report\">Download</a>"
      final_data = [['', @sync_source.time.strftime('%F %T'), button]] + progress_data
      [final_data, progress_count + 1]
    end
  end

  def count; end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_progress
    ManageSyncHistory.fetch_progress(page, per_page, @sync_source.id)
  end

  def columns
    %w(id created_at report)
  end
end
