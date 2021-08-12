# Interviews
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # Interview
  class Interview < ApplicationRecord
    belongs_to :organization
    enum interview_status: { '0' => 'In Progress', '1' => 'Complete' }, _prefix: :interview
    has_many :interview_notes, dependent: :destroy
    before_save :purify_value

    def purify_value
      self.metadata_status = metadata_status.to_i
      self.media_host = Interviews::Interview.media_hosts[media_host] if media_host == 'Host'
    end

    def interview_status_info
      notes_status = !interview_notes.pluck(:status).include?(false)
      index_available = true
      transcript_available = true

      color = color_grading['0']
      process_status = 'In Progress'

      case metadata_status.to_s
      when '4'
        process_status = listing_metadata_status['4']
        color = color_grading['4']
      when '3'
        if notes_status && index_available && transcript_available
          color = color_grading['3']
          process_status = 'Completed'
        else
          process_status = 'In Progress'
          color = color_grading['0']
        end
      when '-1', ''
        process_status = ''
        color = ''
      end

      [color, process_status]
    end

    def interview_metadata_status
      color_grading[metadata_status.to_s]
    end

    def color_grading
      { '-1' => 'color: #000;', '0' => 'color: #1a1aff;', '1' => 'color: #cd2200;', '2' => 'color: #9c43b6;', '3' => 'color: #008b17;', '4' => 'color: #279ade;', '' => 'color: #000;' }
    end

    def listing_metadata_status
      { '-1' => 'Please Select', '4' => 'Pending', '0' => 'In Process', '1' => 'Ready for QC', '2' => 'Active QC', '3' => 'Complete' }
    end

    def listing_media_host
      { 'Host' => 'Other', 'Avalon' => 'Avalon', 'Aviary' => 'Aviary', 'Brightcove' => 'Brightcove', 'Kaltura' => 'Kaltura', 'SoundCloud' => 'SoundCloud', 'Vimeo' => 'Vimeo', 'YouTube' => 'YouTube' }
    end

    searchable do
      integer :id, stored: true
      integer :organization_id, stored: true
      string :title, stored: true
      string :accession_number, stored: true
      string :title_accession_number, stored: true do
        title + ' ' + accession_number
      end
      string :series_id, stored: true
      string :collection_id, stored: true
      string :document_type, stored: true do
        'interview'
      end
      string :status, stored: true
      string :interviewee, multiple: true, stored: true
      string :interviewer, multiple: true, stored: true
      string :interview_date, stored: true
      string :date_non_preferred_format, stored: true
      string :collection_name, stored: true
      string :collection_link, stored: true
      string :series_id, stored: true
      string :series, stored: true
      string :series_link, stored: true
      string :media_format, stored: true
      text :summary, stored: true
      string :keywords, multiple: true, stored: true
      string :subjects, multiple: true, stored: true
      integer :notes_count, stored: true do
        interview_notes.count
      end
      integer :notes_unresolve_count, stored: true do
        interview_notes.where(status: false).count
      end
      integer :notes_resolve_count, stored: true do
        interview_notes.where(status: true).count
      end
      string :thesaurus_keywords, stored: true do
        Thesaurus::Thesaurus.find_by_id(thesaurus_keywords).try(:title)
      end
      string :thesaurus_subjects, stored: true do
        Thesaurus::Thesaurus.find_by_id(thesaurus_subjects).try(:title)
      end
      string :thesaurus_titles, stored: true do
        Thesaurus::Thesaurus.find_by_id(thesaurus_titles).try(:title)
      end
      text :transcript_sync_data, stored: true
      text :transcript_sync_data_translation, stored: true
      string :media_host, stored: true
      text :media_url, stored: true do
        media_url.present? ? media_url : 'None'
      end
      string :media_duration, stored: true do
        media_duration.present? ? media_duration : 'None'
      end
      string :media_filename, stored: true do
        media_filename.present? ? media_filename : 'None'
      end
      string :media_type, stored: true do
        media_type.present? ? media_type : 'None'
      end
      string :format_info, stored: true, multiple: true do
        format_info.present? ? format_info.join(',') : 'None'
      end
      text :right_statement, stored: true do
        right_statement.present? ? right_statement : 'None'
      end
      text :usage_statement, stored: true do
        usage_statement.present? ? usage_statement : 'None'
      end
      text :acknowledgment, stored: true do
        acknowledgment.present? ? acknowledgment : 'None'
      end
      string :language_info, stored: true do
        language_info.present? ? language_info : 'None'
      end
      boolean :include_language, stored: true do
        include_language.present? ? include_language : 'None'
      end
      string :language_for_translation, stored: true do
        language_for_translation.present? ? language_for_translation : 'None'
      end
      string :miscellaneous_cms_record_id, stored: true do
        miscellaneous_cms_record_id.present? ? miscellaneous_cms_record_id : 'None'
      end
      string :miscellaneous_ohms_xml_filename, stored: true do
        miscellaneous_ohms_xml_filename.present? ? miscellaneous_ohms_xml_filename : 'None'
      end
      boolean :miscellaneous_use_restrictions, stored: true do
        miscellaneous_use_restrictions.present? ? miscellaneous_use_restrictions : 'None'
      end
      text :miscellaneous_sync_url, stored: true do
        miscellaneous_sync_url.present? ? miscellaneous_sync_url : 'None'
      end
      text :miscellaneous_user_notes, stored: true do
        miscellaneous_user_notes.present? ? miscellaneous_user_notes : 'None'
      end
      integer :interview_status, stored: true do
        interview_status.present? ? interview_status : 'None'
      end
      integer :status, stored: true do
        status.present? ? status : 'None'
      end

      integer :created_by, stored: true do
        created_by_id.present? ? created_by_id : 'None'
      end

      integer :updated_by, stored: true do
        updated_by_id.present? ? updated_by_id : 'None'
      end

      integer :created_at, stored: true do
        created_at.to_i if created_at.present?
      end

      integer :updated_at, stored: true do
        updated_at.to_i if updated_at.present?
      end

      text :title, stored: true
      text :accession_number, stored: true
      text :title_accession_number, stored: true do
        title + ' ' + accession_number
      end
      text :series_id, stored: true
      text :collection_id, stored: true
      text :interviewee, stored: true
      text :interviewee, stored: true
      text :interviewer, stored: true
      text :date_non_preferred_format, stored: true
      text :collection_name, stored: true
      text :collection_link, stored: true
      text :series_id, stored: true
      text :series, stored: true
      text :series_link, stored: true
      text :media_format, stored: true
      text :keywords, stored: true
      text :subjects, stored: true
      text :media_host, stored: true
      text :media_url, stored: true do
        media_url.present? ? media_url : 'None'
      end
      text :media_filename, stored: true do
        media_filename.present? ? media_filename : 'None'
      end
      text :media_type, stored: true do
        media_type.present? ? media_type : 'None'
      end
      text :format_info, stored: true do
        format_info.present? ? format_info.join(',') : 'None'
      end
      text :language_info, stored: true do
        language_info.present? ? language_info : 'None'
      end
      text :language_for_translation, stored: true do
        language_for_translation.present? ? language_for_translation : 'None'
      end
      text :miscellaneous_cms_record_id, stored: true do
        miscellaneous_cms_record_id.present? ? miscellaneous_cms_record_id : 'None'
      end
      text :miscellaneous_ohms_xml_filename, stored: true do
        miscellaneous_ohms_xml_filename.present? ? miscellaneous_ohms_xml_filename : 'None'
      end
    end

    def self.solr_path
      ENV['SOLR_URL'].blank? ? "http://127.0.0.1:8983/solr/#{Rails.env}" : ENV['SOLR_URL']
    end

    def self.solr_connect
      RSolr.connect url: solr_path
    end

    def self.remove_unwanted_search_chars(single_query)
      single_query = single_query.gsub(%r{[\/\\()|'"*:^~`{}]}, '')
      single_query = single_query.gsub(/]/, '')
      single_query.delete '['
    end

    def self.search_perp(query, field)
      limiter = ''
      if query.present?
        if query.include?(' ')
          query_raw = query.split(' ')
          limiter_inner = []
          query_raw.each do |single_query|
            single_query = remove_unwanted_search_chars(single_query)
            limiter_inner << "#{field}:*#{single_query}*"
          end
          limiter = " ( #{limiter_inner.join(' AND ')}) "
        else
          query = remove_unwanted_search_chars(query)
          limiter = "#{field}:*#{query}*"
        end
      end
      limiter
    end

    def self.straight_search_perp(query, field)
      limiter = ''
      if query.present?
        if query.include?(' ')
          query_raw = query.split(' ')
          limiter_inner = []
          query_raw.each do |single_query|
            single_query = remove_unwanted_search_chars(single_query)
            limiter_inner << "#{field}:\"#{single_query}\""
          end
          limiter = " ( #{limiter_inner.join(' AND ')}) "
        else
          query = remove_unwanted_search_chars(query)
          limiter = "#{field}:\"#{query}\""
        end
      end
      limiter
    end

    def self.fetch_interview_list(page, per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false })
      q = params[:search][:value] if params.present? && params.key?(:search) && params[:search].key?(:value)
      solr_url = Interviews::Interview.solr_path
      select_url = "#{solr_url}/select"
      solr_q_condition = '*:*'
      complex_phrase_def_type = false
      fq_filters = ' document_type_ss:interview  '
      if q.present?
        counter = 0
        fq_filters_inner = ''
        JSON.parse(export_and_current_organization[:current_organization][:interview_search_column]).each do |_, value|
          if value['status'] == 'true' || value['status'].to_s.to_boolean?
            unless value['value'].to_s == 'id_is' && q.to_i <= 0

              alter_search_wildcard = value['value']
              alter_search_wildcard_string = alter_search_wildcard.clone

              alter_search_wildcard.sub! '_ss', '_texts'
              alter_search_wildcard.sub! '_sms', '_texts'
              fq_filters_inner += if counter > 0
                                    " OR  #{search_perp(q, alter_search_wildcard)} "
                                  else
                                    " #{search_perp(q, alter_search_wildcard)} "
                                  end
              counter += 1
              fq_filters_inner += if counter > 0
                                    " OR  #{search_perp(q, alter_search_wildcard_string)} "
                                  else
                                    " #{search_perp(q, alter_search_wildcard_string)} "
                                  end

              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_wildcard)} "
              fq_filters_inner += " OR  #{straight_search_perp(q, alter_search_wildcard_string)} "
              counter += 1
            end
          end
        end
        fq_filters += " AND (#{fq_filters_inner}) " unless fq_filters_inner.blank?
      end
      filters = []
      filters << fq_filters
      filters << limit_condition if limit_condition.present?
      query_params = { q: solr_q_condition, fq: filters.flatten }
      query_params[:fq] << if export_and_current_organization[:current_organization].present?
                             "organization_id_is:#{export_and_current_organization[:current_organization].id}"
                           else
                             'id_is:0'
                           end
      query_params[:defType] = 'complexphrase' if complex_phrase_def_type
      query_params[:wt] = 'json'
      total_response = Curl.post(select_url, query_params)
      begin
        total_response = JSON.parse(total_response.body_str)
      rescue StandardError
        total_response = { 'response' => { 'numFound' => 0 } }
      end
      query_params[:sort] = "#{sort_column} #{sort_direction}" if sort_column.present? && sort_direction.present?
      if export_and_current_organization[:export]
        query_params[:start] = 0
        query_params[:rows] = 100_000_000
      else
        query_params[:start] = (page - 1) * per_page
        query_params[:rows] = per_page
      end
      response = Curl.post(select_url, query_params)
      begin
        response = JSON.parse(response.body_str)
      rescue StandardError
        response = { 'response' => { 'docs' => {} } }
      end
      count = total_response['response']['numFound'].to_i
      [response['response']['docs'], count, {}, export_and_current_organization[:current_organization]]
    end

    def self.column_configuration
      { search_columns: { title_accession_number: true, collection_id: true, series_id: true }, display_columns: { title_accession_number: true, collection_id: true, series_id: true } }
    end

    def reindex
      Sunspot.index self
      Sunspot.commit
    end
  end
end
