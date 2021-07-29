# SyncProgressDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SyncProgressDatatable < ApplicationDatatable
  def initialize(view, sync_source)
    @view = view
    @sync_source = sync_source
  end

  private

  def data
    all_progress, progress_count = fetch_progress
    progress_data = all_progress.map do |progress|
      [].tap do |column|
        column << progress.id
        column << progress.title
        column << progress.external_resource_id
      end
    end
    [progress_data, progress_count]
  end

  def count; end

  def fetch_progress_all
    fetch_progress
  end

  def fetch_progress
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    IntegrationSyncState.fetch_progress(page, per_page, sort_column, sort_direction, params, @sync_source.id)
  end

  def columns
    %w(id title external_resource_id)
  end
end
