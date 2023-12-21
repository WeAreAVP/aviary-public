# Interviews
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # Interview
  class Interview < ApplicationRecord
    belongs_to :organization
    validates :title, :media_format, presence: true
    has_many :interview_notes, dependent: :destroy
    has_many :file_transcripts, dependent: :destroy
    has_many :file_indexes, dependent: :destroy
    before_save :purify_value, :interview_status_info
    before_create :update_thesaurus
    validates_presence_of :language_for_translation, if: :include_language?
    validate :validate_date_format, if: :interview_date?

    def validate_date_format
      date_array = interview_date.split('-')
      if date_array.length == 3
        unless (date_array[0].to_i >= 1900 && date_array[0].to_i <= Date.today.year) && (date_array[1].to_i >= 1 && date_array[1].to_i <= 12) && (date_array[2].to_i >= 1 && date_array[2].to_i <= 31)
          errors.add(:interview_date, 'Date must be in the following formats: yyyy-mm-dd or yyyy-mm or yyyy')
        end
      elsif date_array.length == 2
        unless (date_array[0].to_i >= 1900 && date_array[0].to_i <= Date.today.year) && (date_array[1].to_i >= 1 && date_array[1].to_i <= 12)
          errors.add(:interview_date, 'Date must be in the following formats: yyyy-mm-dd or yyyy-mm or yyyy')
        end
      elsif date_array.length == 1
        unless date_array[0].to_i >= 1900 && date_array[0].to_i <= Date.today.year
          errors.add(:interview_date, 'Date must be in the following formats: yyyy-mm-dd or yyyy-mm or yyyy')
        end
      else
        errors.add(:interview_date, 'Date must be in the following formats: yyyy-mm-dd or yyyy-mm or yyyy')
      end
    end

    def update_thesaurus
      thesaurus_settings = ::Thesaurus::ThesaurusSetting.where(organization_id: organization_id, is_global: true, thesaurus_type: 'index').try(:first)
      if thesaurus_settings.present?
        self.thesaurus_keywords = thesaurus_settings.thesaurus_keywords
        self.thesaurus_subjects = thesaurus_settings.thesaurus_subjects
      end
      thesaurus_settings
    end

    def purify_value
      self.metadata_status = metadata_status.to_i
      self.media_host = listing_media_host[media_host] if media_host == 'Host'
    end

    def interview_status_info
      notes_status = !interview_notes.pluck(:status).include?(false)
      index_available = true
      transcript_available = true

      color = color_grading['0']
      process_status = 'In Process'

      case metadata_status.to_s
      when '4'
        process_status = listing_metadata_status['4']
        color = color_grading['4']
      when '3'
        if notes_status && index_available && transcript_available
          color = color_grading['3']
          process_status = 'Completed'
        else
          process_status = 'In Process'
          color = color_grading['0']
        end
      when '-1', ''
        process_status = ''
        color = ''
      end

      if miscellaneous_ohms_xml_filename.present? && !miscellaneous_ohms_xml_filename.include?('.xml')
        self.miscellaneous_ohms_xml_filename = miscellaneous_ohms_xml_filename + '.xml'
      end

      self.interview_status = process_status
      [color, process_status]
    end

    def interview_sync_status
      color = color_grading['0']
      case sync_status.to_s
      when '4'
        color = color_grading['4']
      when '3'
        color = color_grading['3']
      when '-1', ''
        color = ''
      end
      [color, listing_metadata_status[sync_status.to_s]]
    end

    def interview_metadata_status
      color_grading[metadata_status.to_s]
    end

    def color_grading
      { '-1' => 'color: #000;', '0' => 'color: #1a1aff;', '1' => 'color: #cd2200;', '2' => 'color: #9c43b6;', '3' => 'color: #008b17;', '4' => 'color: #279ade;', '' => 'color: #000;' }
    end

    def color_grading_index
      { '-1' => 'color: #000;', '0' => 'color: #1a1aff;', '1' => 'color: #cd2200;', '2' => 'color: #9c43b6;', '3' => 'color: #008b17;', '4' => 'color: #aaaaaa;', '' => 'color: #000;' }
    end

    def listing_metadata_status
      { '-1' => 'Please Select', '4' => 'Pending', '0' => 'In Process', '1' => 'Ready for QC', '2' => 'Active QC', '3' => 'Complete' }
    end

    def listing_media_host
      { 'Host' => 'Other', 'Avalon' => 'Avalon', 'Aviary' => 'Aviary', 'Brightcove' => 'Brightcove', 'Kaltura' => 'Kaltura', 'SoundCloud' => 'SoundCloud', 'Vimeo' => 'Vimeo', 'YouTube' => 'YouTube' }
    end

    def listing_metadata_index_status
      { '-1' => 'Please Select', '5' => 'Pending', '0' => 'In Process', '1' => 'Ready for QC', '2' => 'Active QC', '3' => 'Complete', '4' => 'Not Applicable' }
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
      string :record_status, multiple: false, stored: true
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
      string :collection_id_series_id, stored: true do
        (collection_id.gsub(' ', '') + ' ' + series_id.gsub(' ', '')).strip
      end
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
        ::Thesaurus::Thesaurus.find_by_id(thesaurus_keywords).try(:title)
      end
      string :thesaurus_subjects, stored: true do
        ::Thesaurus::Thesaurus.find_by_id(thesaurus_subjects).try(:title)
      end
      string :thesaurus_titles, stored: true do
        ::Thesaurus::Thesaurus.find_by_id(thesaurus_titles).try(:title)
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
        miscellaneous_use_restrictions.nil? ? false : miscellaneous_use_restrictions
      end
      text :miscellaneous_sync_url, stored: true do
        miscellaneous_sync_url.present? ? miscellaneous_sync_url : 'None'
      end
      text :miscellaneous_user_notes, stored: true do
        miscellaneous_user_notes.present? ? miscellaneous_user_notes : 'None'
      end
      string :interview_status, stored: true do
        interview_status_info.try(:second).present? ? interview_status_info.try(:second) : ''
      end

      string :interview_color, stored: true do
        interview_status_info.try(:first).present? ? interview_status_info.try(:first) : '#000000'
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

      string :created_at, stored: true do
        Time.at(created_at.to_i).strftime('%Y-%m-%d') if created_at.present?
      end

      string :updated_at, stored: true do
        Time.at(updated_at.to_i).strftime('%Y-%m-%d') if updated_at.present?
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
      text :collection_id_series_id, stored: true do
        collection_id.gsub(' ', '') + ' ' + series_id.gsub(' ', '')
      end
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
      integer :ohms_assigned_user_id, stored: true do
        ohms_assigned_user_id.present? ? ohms_assigned_user_id : 'None'
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

    def self.collection_series(interview)
      interview.collection_id.gsub(' ', '') + ' ' + interview.series_id.gsub(' ', '')
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

    def self.fetch_interview_list(page, per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false, organization_user: false, use_organization: true })
      q = params[:search][:value] if params.present? && params.key?(:search) && params[:search].key?(:value)
      solr_url = Interviews::Interview.solr_path
      select_url = "#{solr_url}/select"
      solr_q_condition = '*:*'
      complex_phrase_def_type = false
      fq_filters = ' document_type_ss:interview  '

      if params[:collection_id].present?
        fq_filters += " AND collection_id_series_id_ss:\"#{params[:collection_id].gsub('+', ' ')}\" "
      end
      if export_and_current_organization[:organization_user].present? && export_and_current_organization[:organization_user].role.system_name == 'ohms_assigned_user'
        fq_filters += " AND ohms_assigned_user_id_is:#{export_and_current_organization[:organization_user]['user_id']} "
      end
      if q.present?
        counter = 0
        fq_filters_inner = ''
        JSON.parse(export_and_current_organization[:current_organization][:interview_search_column]).each do |_, value|
          if !value['value'].to_s.include?('_bs') && (value['status'] == 'true' || value['status'].to_s.to_boolean?)
            unless value['value'].to_s == 'id_is' && q.to_i <= 0
              alter_search_wildcard = value['value']
              alter_search_wildcard_string = alter_search_wildcard.clone

              if alter_search_wildcard == 'created_at_is'
                alter_search_wildcard = 'created_at_ss'
                alter_search_wildcard_string = 'created_at_ss'
              end

              if alter_search_wildcard == 'updated_at_is'
                alter_search_wildcard = 'updated_at_ss'
                alter_search_wildcard_string = 'updated_at_ss'
              end

              if alter_search_wildcard == 'updated_by_id_is'
                alter_search_wildcard = 'updated_by_ss'
                alter_search_wildcard_string = 'updated_by_ss'
              end

              if alter_search_wildcard == 'created_by_id_is'
                alter_search_wildcard = 'created_by_id_ss'
                alter_search_wildcard_string = 'created_by_id_ss'
              end

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

      if params.present? && params.key?(:notes_only)
        fq_filters += ' AND notes_count_is:[1 TO *] '
      end

      filters = []
      filters << fq_filters
      filters << limit_condition if limit_condition.present?
      query_params = { q: solr_q_condition, fq: filters.flatten }
      query_params[:fq] << if export_and_current_organization[:current_organization].present?
                             (export_and_current_organization[:use_organization] ? "organization_id_is:#{export_and_current_organization[:current_organization].id}" : '')
                           else
                             'id_is:0'
                           end

      query_params[:defType] = 'complexphrase' if complex_phrase_def_type
      query_params[:wt] = 'json'

      total_response = Curl.post(select_url, URI.encode_www_form(query_params))

      begin
        total_response = JSON.parse(total_response.body_str)
      rescue StandardError
        total_response = { 'response' => { 'numFound' => 0 } }
      end
      query_params[:sort] = case sort_column.to_s
                            when 'updated_at_ss'
                              "updated_at_is #{sort_direction}"
                            when 'created_at_ss'
                              "created_at_is #{sort_direction}"
                            else
                              "#{sort_column} #{sort_direction}"
                            end
      if params.present? && params.key?(:notes_only)
        query_params[:sort] = 'notes_unresolve_count_is desc'
      end
      if export_and_current_organization[:export]
        query_params[:start] = 0
        query_params[:rows] = 100_000_000
      else
        query_params[:start] = (page - 1) * per_page
        query_params[:rows] = per_page
      end
      response = Curl.post(select_url, URI.encode_www_form(query_params))
      begin
        response = JSON.parse(response.body_str)
      rescue StandardError
        response = { 'response' => { 'docs' => {} } }
      end
      count = if total_response.present? && total_response['response'].present? && total_response['response']['numFound'].present?
                total_response['response']['numFound'].to_i
              else
                0
              end

      [response['response']['docs'], count, {}, export_and_current_organization[:current_organization]]
    end

    def self.fetch_interview_collection_id(collection_id, _params, _limit_condition, export_and_current_organization = { export: true, current_organization: false })
      solr_url = Interviews::Interview.solr_path
      select_url = "#{solr_url}/select"
      solr_q_condition = '*:*'
      complex_phrase_def_type = false
      fq_filters = " document_type_ss:interview AND collection_id_series_id_ss:#{collection_id} "
      filters = []
      filters << fq_filters
      query_params = { q: solr_q_condition, fq: filters.flatten, facet: true, 'facet.field' => %w[record_status_ss interview_status_ss] }

      query_params[:fq] << if export_and_current_organization[:current_organization].present?
                             "organization_id_is:#{export_and_current_organization[:current_organization].id}"
                           else
                             'id_is:0'
                           end
      query_params[:defType] = 'complexphrase' if complex_phrase_def_type
      query_params[:wt] = 'json'

      total_response = Curl.post(select_url, URI.encode_www_form(query_params))

      begin
        total_response = JSON.parse(total_response.body_str)

        if total_response['error'].present?
          Rails.logger.error total_response['error']['msg']
          raise 'There is an error in the query'
        end
      rescue StandardError
        total_response = { 'response' => { 'numFound' => 0 } }
      end

      online_count = if total_response.present? && total_response['facet_counts'].present? && total_response['facet_counts']['facet_fields'].present? && total_response['facet_counts']['facet_fields']['record_status_ss'].present? && total_response['facet_counts']['facet_fields']['record_status_ss'].find_index('Online').present?
                       total_response['facet_counts']['facet_fields']['record_status_ss'][total_response['facet_counts']['facet_fields']['record_status_ss'].find_index('Online') + 1]
                     else
                       0
                     end
      complete_count = if total_response.present? && total_response['facet_counts'].present? && total_response['facet_counts']['facet_fields'].present? && total_response['facet_counts']['facet_fields']['interview_status_ss'].present? && total_response['facet_counts']['facet_fields']['interview_status_ss'].find_index('Completed').present?
                         total_response['facet_counts']['facet_fields']['interview_status_ss'][total_response['facet_counts']['facet_fields']['interview_status_ss'].find_index('Completed') + 1]
                       else
                         0
                       end

      [online_count, complete_count]
    end

    def self.fetch_interview_collections_list(_page, _per_page, sort_column, sort_direction, params, limit_condition, export_and_current_organization = { export: false, current_organization: false })
      q = params[:search][:value] if params.present? && params.key?(:search) && params[:search].key?(:value)
      solr_url = Interviews::Interview.solr_path
      select_url = "#{solr_url}/select"
      solr_q_condition = '*:*'
      complex_phrase_def_type = false
      fq_filters = ' document_type_ss:interview AND collection_id_series_id_ss:["" TO *] '
      if q.present?
        counter = 0
        fq_filters_inner = ''
        %w[collection_id_texts collection_name_texts series_id_texts].each do |name|
          fq_filters_inner += counter > 0 ? "  OR  #{search_perp(q, name)}  " : "  #{search_perp(q, name)}  "
          fq_filters_inner += " OR  #{straight_search_perp(q, name)} "

          counter += 1
        end

        fq_filters += " AND (#{fq_filters_inner}) " unless fq_filters_inner.blank?
      end
      filters = []
      filters << fq_filters
      filters << limit_condition if limit_condition.present?
      query_params = { q: solr_q_condition, fq: filters.flatten, group: true, 'group.field' => 'collection_id_series_id_ss' }
      query_params[:fq] << if export_and_current_organization[:current_organization].present?
                             "organization_id_is:#{export_and_current_organization[:current_organization].id}"
                           else
                             'id_is:0'
                           end
      query_params[:defType] = 'complexphrase' if complex_phrase_def_type
      query_params[:wt] = 'json'
      query_params[:sort] = if sort_column.present? && sort_direction.present? && sort_column != 'id_is'
                              "#{sort_column} #{sort_direction}"
                            else
                              'collection_id_series_id_ss asc'
                            end
      total_response = Curl.post(select_url, URI.encode_www_form(query_params))
      begin
        total_response = JSON.parse(total_response.body_str)
      rescue StandardError
        total_response = { 'response' => { 'numFound' => 0 } }
      end
      count = if total_response.present? && total_response['grouped'].present? && total_response['grouped']['collection_id_series_id_ss'].present? && total_response['grouped']['collection_id_series_id_ss']['groups'].present?
                total_response['grouped']['collection_id_series_id_ss']['groups'].length
              else
                0
              end
      [total_response['grouped']['collection_id_series_id_ss']['groups'], count, {}, export_and_current_organization[:current_organization]]
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
