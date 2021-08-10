# InterviewsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class InterviewsDatatable < ApplicationDatatable
  delegate :can?, :interviews_manager_path, :edit_interviews_manager_path, :check_valid_array, to: :@view

  def initialize(view, current_organization = nil)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_interviews, interviews_count = interviews
    users_data = all_interviews.map do |resource|
      [].tap do |column|
        if @current_organization.interview_display_column.present? && JSON.parse(@current_organization.interview_display_column).present?
          JSON.parse(@current_organization.interview_display_column)['columns_status'].each do |_, value|
            field_status = value['status']
            column << manage(value, resource) if field_status.to_s.to_boolean?
          end
        end
        column << links(resource)
      end
    end

    [users_data, interviews_count]
  end

  def manage(value, resource)
    if value['value'] == 'updated_by_id_is'
      if resource['updated_by_is'].present? && User.find_by(id: resource['updated_by_is']).present?
        User.find_by(id: resource['updated_by_is']).try('first_name').to_s + ' ' + User.find_by(id: resource['updated_by_is']).try('last_name')
      else
        'none'
      end
    elsif value['value'] == 'created_by_id_is'
      if resource['created_by_is'].present? && User.find_by(id: resource['created_by_is']).present?
        User.find_by(id: resource['created_by_is']).try('first_name').to_s + ' ' + User.find_by(id: resource['created_by_is']).try('last_name')
      else
        'none'
      end
    elsif value['value'] == 'created_at_is'
      Time.at(resource[value['value']]).to_date
    elsif value['value'] == 'updated_at_is'
      Time.at(resource[value['value']]).to_date
    else
      check_valid_array(resource[value['value']], value['value'])
    end
  end

  def count; end

  def interviews
    @interviews ||= fetch_interview
  end

  def fetch_interview
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    Interviews::Interview.fetch_interview_list(page, per_page, sort_column, sort_direction, params, {}, export: false, current_organization: @current_organization)
  end

  def sort_column
    columns(JSON.parse(@current_organization.interview_display_column)['columns_status'])[params[:order]['0'][:column].to_i]
  end

  def links(interview)
    html = ''
    html += link_to 'Metadata', edit_interviews_manager_path(interview['id_is']), class: 'btn-sm btn-link mr-1 float-left'
    html += '<div class="dropdown float-left">'
    html += ' <button type="button" class="btn btn-sm mr-2 btn-outline-primary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Export</button>'
    html += ' <div class="dropdown-menu dropdown-menu-right" x-placement="bottom-end" style="position: absolute; transform: translate3d(137px, 33px, 0px); top: 0px; left: 0px; will-change: transform;">'
    html += '   <a class="dropdown-item export_btn" href="#">XML</a>'
    html += '   <a class="dropdown-item export_btn" href="#">CSV</a>'
    html += ' </div>'
    html += '</div>'
    html += link_to 'Delete', 'javascript://', class: 'btn-sm btn-danger interview_delete', data: { url: interviews_manager_path(interview['id_is']), name: interview['title_ss'] }
    html
  end

  def columns(resource_search_column = false)
    columns_allowed = []
    if resource_search_column && resource_search_column.present?
      resource_search_column.each do |_, value|
        if !value['status'].blank? && value['status'].to_s.to_boolean?
          columns_allowed << value['value']
        end
      end
    end
    columns_allowed
  end
end

