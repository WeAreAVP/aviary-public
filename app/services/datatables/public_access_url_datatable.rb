# UsersDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class PublicAccessUrlDatatable < ApplicationDatatable
  delegate :edit_admin_user_path, :options_for_select, :select_tag, :content_tag, :date_time_format, :check_box_tag, :collection_collection_resource_path, :public_access_urls_edit_path, to: :@view
  attr_accessor :current_user_details

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_progress, progress_count = fetch_data
    progress_data = all_progress.map do |progress|
      [].tap do |column|
        column << progress.title
        column << progress.collection_name
        column << (progress.access_type == 'limited_access_url' ? 'Limited Access URL' : 'Evergreen URL')
        column << progress.duration.sub(' - ', ' ')
        column << '<button data-toggle="tooltip" data-placement="top" class="btn-sm btn-custom-small_all copy-public-access-url" data-clipboard-text=' + progress.url + ' javascript:void(0)> Copy URL</button>'
        var_html = '<label class="toggle-switch">'
        var_html += check_box_tag 'status', 'no', progress.status, class: 'toggle-switch__input public_access_status', data: { id: progress.id }
        var_html += '<span class="toggle-switch__slider"></span>'
        var_html += '</label>'

        column << var_html
        column << if progress.information.present? && JSON.parse(progress.information).present?
                    JSON.parse(progress.information)['start_time'].present? ? JSON.parse(progress.information)['start_time'] : 'N/A'
                  else
                    'N/A'
                  end
        column << date_time_format(progress.created_at)
        column << date_time_format(progress.updated_at)

        links = link_to 'Edit', 'javascript://', class: 'btn-sm btn-success access-edit ', data: { url: public_access_urls_edit_path(id: progress.id), type: progress.access_type }
        links += link_to 'Delete', 'javascript://', class: 'btn-sm btn-danger access-delete ml-1', data: { id: progress.id }
        links += link_to 'View Resource', collection_collection_resource_path(progress.collection_id, progress.collection_resource_id), class: 'btn-sm btn-default access-view-resource ml-1', data: { id: progress.id }
        column << links
      end
    end
    [progress_data, progress_count]
  end

  def count; end

  def fetch_progress_all
    fetch_data
  end

  def fetch_data
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    PublicAccessUrl.fetch_data(page, per_page, sort_column, sort_direction, params, @current_organization.id)
  end

  def columns
    %w(title collections.name access_type duration url public_access_urls.status public_access_urls.information public_access_urls.created_at public_access_urls.updated_at)
  end
end
