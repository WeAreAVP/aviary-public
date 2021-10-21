# InterviewsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class InterviewsDatatable < ApplicationDatatable
  delegate :can?, :interviews_manager_path, :interviews_list_notes_path, :interviews_update_note_path, :interviews_interview_index_path,
           :edit_interviews_manager_path, :export_interviews_manager_path, :check_valid_array,
           :bulk_resource_list_interviews_managers_path, :preview_interviews_manager_path, :interviews_transcript_path, to: :@view

  def initialize(view, current_organization = nil)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_interviews, interviews_count = interviews
    users_data = all_interviews.map do |resource|
      [].tap do |column|
        column << "<input type='checkbox' class='interviews_selections interviews_selections-#{resource['id_is']}'
                    data-url='#{bulk_resource_list_interviews_managers_path(id: resource['id_is'])}' data-id='#{resource['id_is']}' />"
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
    elsif value['value'] == 'interview_status_ss'
      "<span style='#{resource['interview_color_ss']}'>  #{resource['interview_status_ss'].present? ? resource['interview_status_ss'] : ' None '}</span>"
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
    this_interview = Interviews::Interview.find_by(id: interview['id_is'])
    color_metadata = this_interview.try(:interview_metadata_status)
    index_color_metadata = this_interview.try(:index_status)
    html = '<div class="d-flex align-items-center"><div class="action-btn-holder btn-group">'
    html += link_to 'Preview', preview_interviews_manager_path(interview['id_is']), class: 'btn-interview btn-sm btn-link'
    html += link_to 'Metadata', edit_interviews_manager_path(interview['id_is']), class: 'btn-interview btn-sm btn-link', style: color_metadata.to_s, data: {
      toggle: 'tooltip', placement: 'top', title: (this_interview.present? ? this_interview.listing_metadata_status[this_interview.metadata_status.to_s] : '')
    }
    html += link_to 'Index', interviews_interview_index_path(interview['id_is']), class: 'btn-interview btn-sm btn-link', style: this_interview.color_grading_index[index_color_metadata.to_s], data: {

    }
    html += link_to (this_interview.try(:interview_transcript).present? && this_interview.interview_transcript.associated_file_updated_at.present? ? 'Re-Upload Transcript' : 'Upload Transcript'), 'javascript:void(0);',
                    class: 'btn-interview btn-sm btn-link interview_transcript_upload ',
                    style: transcripts_color(this_interview), id: 'interview_tupload_' + interview['id_is'].to_s, data: { id: "upload_#{interview['id_is']}", url: interviews_transcript_path(interview['id_is']) }

    html += link_to 'Notes', 'javascript://', class: 'btn-interview btn-sm btn-link interview_notes ' + notes_color(interview), id: 'interview_note_' + interview['id_is'].to_s, data: {
      id: interview['id_is'], url: interviews_list_notes_path(interview['id_is'], 'json'), updateurl: interviews_update_note_path(interview['id_is'], 'json')
    }
    html += '</div><div class="btn-interview-dropdown dropdown d-inline-block">'

    html += ' <button type="button" class="btn btn-lg text-custom-dropdown btn-link text-primary" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><i class="fa fa-ellipsis-v"></i></button>'
    html += ' <div class="dropdown-menu dropdown-menu-right" x-placement="bottom-end" style="position: absolute; transform: translate3d(137px, 33px, 0px); top: 0px; left: 0px; will-change: transform;">'
    html += link_to 'Export XML', export_interviews_manager_path(interview['id_is'], 'xml'), class: 'dropdown-item export_btn'
    html += link_to 'Export CSV', export_interviews_manager_path(interview['id_is'], 'csv'), class: 'dropdown-item export_btn'
    html += '<div class="dropdown-divider"></div>'
    html += link_to 'Delete', 'javascript://', class: ' btn-interview-danger dropdown-item interview_delete', data: { url: interviews_manager_path(interview['id_is']), name: interview['title_ss'] }
    html += ' </div>'
    html += '</div>'
    html += "</div>"
    html
  end

  
  def columns(resource_search_column = false)
    columns_allowed = ['id_is']
    if resource_search_column&.present?
      resource_search_column.each do |_, value|
        if !value['status'].blank? && value['status'].to_s.to_boolean?
          columns_allowed << value['value']
        end
      end
    end
    columns_allowed
  end

  def notes_color(interview)
    if interview['notes_count_is'].present? && interview['notes_count_is'] > 0
      interview['notes_unresolve_count_is'] > 0 ? 'text-danger' : 'text-success'
    else
      'text-secondary'
    end
  end

  def transcripts_color(interview)
    interview_transcript = interview.try(:interview_transcript)
    text_color = 'color: #1a1aff;'
    if interview_transcript.present?
      if interview_transcript.no_transcript
        text_color = 'color: #000;'
      elsif interview_transcript.associated_file_updated_at.present?
        text_color = 'color: #008b17;'
      end
    end
    text_color
  end
end
