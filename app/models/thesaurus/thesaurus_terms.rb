# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Thesaurus
  # ThesaurusTerms
  class ThesaurusTerms < ApplicationRecord
    belongs_to :thesaurus_information, class_name: 'Thesaurus::Thesaurus'

    searchable do
      string :document_type, stored: true do
        'thesaurus_thesaurus_term'
      end
      integer :id, stored: true
      integer :thesaurus_information_id, stored: true
      text :term, stored: true
      string :term, stored: true
    end

    def self.solr_path
      ENV['SOLR_URL'].blank? ? "http://127.0.0.1:8983/solr/#{Rails.env}" : ENV['SOLR_URL']
    end

    def self.solr_connect
      RSolr.connect url: solr_path
    end

    def self.fetch_resources(page, per_page, sort_column, sort_direction, query, thesaurus_id)
      solr_url = solr_path
      select_url = "#{solr_url}/select"
      solr_q_condition = '*:*'
      complex_phrase_def_type = false

      fq = ' document_type_ss:thesaurus_thesaurus_term '
      fq += " AND thesaurus_information_id_is:#{thesaurus_id} " if thesaurus_id.present?
      if query.present?
        fq += ' AND ( '
        query.each_with_index do |term, i|
          fq += ' OR ' if i != 0
          fq += " term_scis:#{term} " if term.present?
        end
        fq += ' ) '
      end

      sort_column = sort_column.sub(/_(ss|sms)$/, '_scis')

      query_params = { q: solr_q_condition, fq: fq }
      query_params[:defType] = 'complexphrase' if complex_phrase_def_type
      query_params[:wt] = 'json'
      query_params[:start] = (page - 1) * per_page
      query_params[:rows] = per_page
      query_params[:sort] = " #{sort_column} #{sort_direction} "

      begin
        response = Curl.post(select_url, URI.encode_www_form(query_params))
        response = JSON.parse(response.body_str)
      rescue StandardError
        response = { 'response' => { 'docs' => {} } }
      end

      response['response']['docs']
    end
  end
end
