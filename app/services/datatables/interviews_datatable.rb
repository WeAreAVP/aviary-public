# InterviewsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class InterviewsDatatable < ApplicationDatatable
  delegate :can?, :interviews_manager_path, :interviews_list_notes_path, :interviews_update_note_path, :interviews_transcript_path,
           :ohms_index_path, :ohms_records_edit_path, :preview_interviews_manager_path, :export_interviews_manager_path, :sync_interviews_manager_path, :check_valid_array, :bulk_resource_list_interviews_managers_path, to: :@view

  def initialize(view, current_organization = nil, organization_user = '', use_organization = true)
    @view = view
    @current_organization = current_organization
    @organization_user = organization_user
    @use_organization = use_organization
  end

  private

  def data
    all_interviews, interviews_count = interviews
    users_data = all_interviews.map do |resource|
      [].tap do |column|
        unless @organization_user.role.system_name == 'ohms_assigned_user'
          column << "<input type='checkbox' class='interviews_selections interviews_selections-#{resource['id_is']}'
                      data-url='#{bulk_resource_list_interviews_managers_path(id: resource['id_is'])}' data-id='#{resource['id_is']}' />"
        end
        if @current_organization.interview_display_column.present? && JSON.parse(@current_organization.interview_display_column).present?
          JSON.parse(@current_organization.interview_display_column)['columns_status'].each do |_, value|
            field_status = value['status']
            column << manage(value, resource) if field_status.to_s.to_boolean? && value['value'] != 'ohms_assigned_user_id_is'
          end
        end
        unless @organization_user.role.system_name == 'ohms_assigned_user'
          column << assignment(resource)
        end
        column << links(resource)
      end
    end

    [users_data, interviews_count]
  end

  def assignment(resource)
    ohms_assigned_user_id_val = resource['ohms_assigned_user_id_is']
    users = @current_organization.organization_ohms_assigned_users.includes(:user).joins(:user).order('users.first_name')
    select_html = '<select class="assign_user" data-call_url="ohms_records/user_assignments/' + resource['id_is'].to_s + '" name="ohms_assigned_user_id"><option value="">Assign User</option>'
    users.each do |user|
      ohms_user = user.user
      is_selected = ' selected="selected"' if ohms_assigned_user_id_val.to_i == ohms_user.id
      select_html += '<option value="' + ohms_user.id.to_s + '" ' + is_selected.to_s + '>' + ohms_user.first_name + ' ' + ohms_user.last_name + '</option>'
    end
    select_html += '</select>'
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
    elsif value['value'] == 'record_status_is'
      resource['record_status_ss']
    elsif value['value'] == 'miscellaneous_use_restrictions_bs' || value['value'] == 'use_restrictions_bs'
      if resource['miscellaneous_use_restrictions_bs']
        'Restricted'
      else
        'Not Restricted'
      end
    elsif value['value'] == 'media_url_texts'
      media_url_val = check_valid_array(resource[value['value']], value['value'])
      if media_url_val != 'None'
        link_to 'Media URL', check_valid_array(resource[value['value']], value['value']), target: '_blank', class: 'btn btn-default'
      else
        ''
      end
    elsif value['value'] == 'interview_status_ss'
      if resource['interview_status_ss'] == 'In Progress'
        resource['interview_status_ss'] = 'In Process'
      end
      "<span style='#{resource['interview_color_ss']}'>  #{resource['interview_status_ss'].present? ? resource['interview_status_ss'] : ' None '}</span>"
    elsif value['value'] == 'created_at_is'
      Time.at(resource[value['value']]).to_date
    elsif value['value'] == 'title_accession_number_ss'
      "#{check_valid_array(resource[value['value']], value['value'])} #{link_to 'Preview', preview_interviews_manager_path(resource['id_is']), class: 'btn-interview-preview'}"
    elsif value['value'] == 'updated_at_is'
      Time.at(resource[value['value']]).to_date
    elsif value['value'] == 'keywords_sms'
      keyword_ids = check_valid_array(resource[value['value']], value['value'])
      if keyword_ids != 'None'
        Thesaurus::ThesaurusTerms.where(id: keyword_ids.split(',')).pluck(:term)
      end
    elsif value['value'] == 'subjects_sms'
      subject_ids = check_valid_array(resource[value['value']], value['value'])
      if subject_ids != 'None'
        Thesaurus::ThesaurusTerms.where(id: subject_ids.split(',')).pluck(:term)
      end
    else
      check_valid_array(resource[value['value']], value['value'], 100)
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
    Interviews::Interview.fetch_interview_list(page, per_page, sort_column, sort_direction, params, {}, export: false, current_organization: @current_organization, organization_user: @organization_user, use_organization: @use_organization)
  end

  def sort_column
    columns(JSON.parse(@current_organization.interview_display_column)['columns_status'])[params[:order]['0'][:column].to_i]
  end

  def links(interview)
    this_interview = Interviews::Interview.find_by(id: interview['id_is'])
    color_metadata = this_interview.try(:interview_metadata_status)
    index_color_metadata = this_interview.try(:index_status)
    html = '<div class="d-flex align-items-center"><div class="action-btn-holder btn-group">'
    unless @organization_user.role.system_name == 'ohms_assigned_user'
      html += link_to 'Metadata', ohms_records_edit_path(interview['id_is']), class: 'btn-interview btn-sm btn-link', style: color_metadata.to_s, data: {
        toggle: 'tooltip', placement: 'top', title: (this_interview.present? ? this_interview.listing_metadata_status[this_interview.metadata_status.to_s] : '')
      }
    end
    html += link_to 'Index', ohms_index_path(interview['id_is']), class: 'btn-interview btn-sm btn-link', style: this_interview.color_grading_index[index_color_metadata.to_s], data: {
      toggle: 'tooltip', placement: 'top', title: (this_interview.present? ? this_interview.listing_metadata_index_status[this_interview.index_status.to_s] : '')
    }

    html += link_to 'Notes', 'javascript://', class: 'btn-interview btn-sm btn-link interview_notes ' + notes_color(interview), id: 'interview_note_' + interview['id_is'].to_s, data: {
      id: interview['id_is'], url: interviews_list_notes_path(interview['id_is'], 'json'), updateurl: interviews_update_note_path(interview['id_is'], 'json')
    }
    unless @organization_user.role.system_name == 'ohms_assigned_user'
      html += link_to (this_interview.try(:file_transcripts).present? && this_interview.file_transcripts.first.associated_file_updated_at.present? ? 'Re-Upload Transcript' : 'Upload Transcript'), 'javascript:void(0);',
                      class: 'btn-interview btn-sm btn-link interview_transcript_upload ',
                      style: transcripts_color(this_interview), id: 'interview_tupload_' + interview['id_is'].to_s, data: { id: "upload_#{interview['id_is']}", url: interviews_transcript_path(interview['id_is']) }
    end
    if this_interview.try(:file_transcripts).present?
      html += link_to 'Sync', sync_interviews_manager_path(interview['id_is']), class: 'btn-interview btn-sm btn-link mr-1 float-left interview_transcript_sync ', id: 'interview_transcript_sync' + interview['id_is'].to_s, data: {
        id: interview['id_is'], url: sync_interviews_manager_path(interview['id_is'], 'json'), updateurl: sync_interviews_manager_path(interview['id_is']),
        toggle: 'tooltip', placement: 'top', title: this_interview.interview_sync_status.second
      }
    end
    html += '</div>'
    unless @organization_user.role.system_name == 'ohms_assigned_user'
      html += '<div class="btn-interview-dropdown dropdown d-inline-block">'

      html += ' <button type="button" class="btn btn-lg text-custom-dropdown btn-link text-primary" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><i class="fa fa-ellipsis-v"></i></button>'
      html += ' <div class="dropdown-menu dropdown-menu-right" x-placement="bottom-end" style="position: absolute; transform: translate3d(137px, 33px, 0px); top: 0px; left: 0px; will-change: transform;">'
      html += link_to 'Export XML', export_interviews_manager_path(interview['id_is'], 'xml'), class: 'dropdown-item export_btn'
      html += '<div class="dropdown-divider"></div>'
      html += link_to 'Delete', 'javascript://', class: ' btn-interview-danger dropdown-item interview_delete', data: { url: interviews_manager_path(interview['id_is']), name: interview['title_ss'] }
      html += ' </div>'
      html += '</div>'
    end
    html += '</div>'
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
    interview_transcript = interview.try(:file_transcripts)
    interview_transcript = interview_transcript.first if interview_transcript.present?
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
