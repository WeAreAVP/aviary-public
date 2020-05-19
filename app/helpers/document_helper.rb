# SearchHelper
module DocumentHelper
  def description_search_fields
    %i[description_title_search_texts description_publisher_search_texts description_rights_statement_search_texts description_source_search_texts
       description_agent_search_texts description_date_search_texts description_coverage_search_texts description_language_search_texts description_description_search_texts
       description_format_search_texts description_identifier_search_texts description_relation_search_texts description_subject_search_texts description_keyword_search_texts description_type_search_texts
       description_preferred_citation_search_texts description_source_metadata_uri_search_texts description_custom_field_values_search_texts]
  end

  def description_simple_fields
    %i[description_title_sms description_publisher_sms description_rights_statement_sms description_source_sms description_agent_sms description_date_sms description_coverage_sms description_language_sms description_description_sms
       description_format_sms description_identifier_sms description_relation_sms description_subject_sms description_keyword_sms description_type_search_facet_sms
       description_preferred_citation_ss description_duration_ss description_source_metadata_uri_ss]
  end

  def index_search_fields
    %i[index_point_title_texts index_point_synopsis_texts index_point_subjects_texts index_point_keywords_texts index_point_partial_script_texts]
  end

  def transcript_search_fields
    %i[transcript_point_text_texts transcript_point_speaker_texts]
  end

  def other_fields
    %i[title_text]
  end

  def tracking_term_separator(value)
    single_keyword = value['keywords']
    delimiters = %w[AND OR]
    all_terms = []
    single_keyword.split(Regexp.union(delimiters)).each do |value_regex|
      if value_regex.include?('NOT')
        single_term = value_regex.split(' NOT ')
        all_terms << single_term.first
      else
        all_terms << value_regex
      end
    end
    all_terms
  end

  def field_relevance_count(document, single_keyword)
    html = ''
    inner_html = ''
    [description_search_fields, index_search_fields, transcript_search_fields, other_fields].reduce([], :concat).each do |values|
      if document.key?("#{values}_occurrence_#{single_keyword}") && document["#{values}_occurrence_#{single_keyword}"].to_i > 0
        title = values.to_s.titleize
        %w[Description Texts Text Search Script Partial Point].each do |single_word|
          title = title.sub! single_word, '' if title.include?(single_word)
        end
        title = title.gsub(/\s+/, '')
        inner_html += "<li>#{title} (#{document["#{values}_occurrence_#{single_keyword}"]})</li>"
      end
    end
    unless inner_html.empty?
      html += "<div class='list'> <label><strong>#{single_keyword.to_s.titleize}:</strong></label><ul style='display:inline;'/>"
      html += inner_html
      html += '</ul>'
      html += '</div>'
    end
    html
  end
end
