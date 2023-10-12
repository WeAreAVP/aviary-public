# InterviewsCollectionsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class InterviewsCollectionsDatatable < ApplicationDatatable
  delegate :can?, :interview_export_path, :interview_list_of_collections_path, to: :@view

  def initialize(view, current_organization = nil)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_interviews, interviews_count = interviews
    users_data = all_interviews.map do |resource|
      count = Interviews::Interview.fetch_interview_collection_id(resource['groupValue'], params, {}, export: true, current_organization: @current_organization)
      [].tap do |column|
        column << "<input type='checkbox' class='interviews_selections interviews_selections-'
                    data-url='' data-id='' />"
        column << "<div class='collection_name' style='max-width: 10rem;'>#{resource['doclist'].present? && resource['doclist']['docs'].present? && resource['doclist']['docs'].try(:first).present? ? resource['doclist']['docs'].try(:first)['collection_name_ss'] : ''}</div>"
        column << "<div class='collection_name' style='max-width: 10rem;'>#{resource['doclist'].present? && resource['doclist']['docs'].present? && resource['doclist']['docs'].try(:first).present? ? resource['doclist']['docs'].try(:first)['collection_id_ss'] : ''}</div>"
        column << (resource['doclist'].present? && resource['doclist']['docs'].present? && resource['doclist']['docs'].try(:first).present? ? resource['doclist']['docs'].try(:first)['series_id_ss'] : '')
        column << (resource['doclist'].present? && resource['doclist']['numFound'].present? ? resource['doclist']['numFound'] : '')
        column << count[1]
        column << count[0]
        column << links(resource)
      end
    end
    [users_data, interviews_count]
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
    Interviews::Interview.fetch_interview_collections_list(page, per_page, sort_column, sort_direction, params, {}, export: false, current_organization: @current_organization)
  end

  def sort_column
    columns(JSON.parse(@current_organization.interview_display_column)['columns_status'])[params[:order]['0'][:column].to_i]
  end

  def links(interview)
    group_value = interview['groupValue'].gsub(' ', '+')
    html = '<div class="d-flex align-items-center"><div class="action-btn-holder btn-group">'
    html += link_to 'Manage Interviews', interview_list_of_collections_path(group_value), class: 'btn-interview btn-sm btn-default btn-link'
    html += link_to 'Export Interviews', interview_export_path(group_value), class: 'btn-interview btn-sm btn-default btn-link'

    html += '</div><div class="btn-interview-dropdown dropdown d-inline-block">'

    html += '</div>'
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
