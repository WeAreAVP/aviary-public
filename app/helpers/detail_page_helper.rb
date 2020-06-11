# Detail Page Helper
module DetailPageHelper
  def count_occurrence(point, session_video_text, type_count, type, is_file_wise = false)
    return type_count if session_video_text.blank?
    session_video_text.each do |_, single_keyword|
      unless single_keyword.blank?
        single_keyword = single_keyword.delete '"'
        if type == 'transcript'
          type_count = count_transcript_occurrence(point, single_keyword, type_count, is_file_wise)
        elsif type == 'index'
          type_count = count_index_occurrence(point, single_keyword, type_count, is_file_wise)
        elsif type == 'description'
          type_count = count_description_occurrence(point, single_keyword, type_count)
        end
      end
    end
    type_count
  end

  def count_transcript_occurrence(transcript_point, single_keyword, transcript_count, is_file_wise)
    transcript_point_sum = count_em(transcript_point.text, single_keyword) + count_em(transcript_point.speaker, single_keyword)
    transcript_count[transcript_point.file_transcript.collection_resource_file_id] ||= {}
    transcript_count[transcript_point.file_transcript.collection_resource_file_id]['total-transcript'] ||= 0
    transcript_count[transcript_point.file_transcript.collection_resource_file_id]['total-transcript'] += transcript_point_sum
    return transcript_count if is_file_wise
    transcript_count[transcript_point.file_transcript.collection_resource_file_id][single_keyword] ||= 0
    transcript_count[transcript_point.file_transcript.collection_resource_file_id][single_keyword] += transcript_point_sum
    transcript_count['individual'] ||= {}
    transcript_count['individual']['transcript'] ||= {}
    transcript_count['individual']['transcript']['id-' + transcript_point.id.to_s] ||= 0
    transcript_count['individual']['transcript']['id-' + transcript_point.id.to_s] += transcript_point_sum
    transcript_count[:single_transcript_count] ||= {}
    transcript_count[:single_transcript_count][transcript_point.file_transcript_id] ||= 0
    transcript_count[:single_transcript_count][transcript_point.file_transcript_id] += transcript_point_sum
    session[:count_presence][:transcript] = true if transcript_count[transcript_point.file_transcript.collection_resource_file_id][single_keyword] > 0 && !session[:count_presence][:transcript]
    transcript_count
  end

  def count_index_occurrence(index_point, single_keyword, index_count, is_file_wise)
    index_point_sum = count_em(index_point.synopsis, single_keyword) + count_em(index_point.title, single_keyword) + count_em(index_point.partial_script, single_keyword) +
                      count_em(index_point.subjects, single_keyword) + count_em(index_point.keywords, single_keyword)

    index_count[index_point.file_index.collection_resource_file_id] ||= {}
    index_count[index_point.file_index.collection_resource_file_id]['total-index'] ||= 0
    index_count[index_point.file_index.collection_resource_file_id]['total-index'] += index_point_sum
    return index_count if is_file_wise

    index_count[index_point.file_index.collection_resource_file_id][single_keyword] ||= 0
    index_count[index_point.file_index.collection_resource_file_id][single_keyword] += index_point_sum

    index_count['individual'] ||= {}
    index_count['individual']['index'] ||= {}
    index_count['individual']['index']['id-' + index_point.id.to_s] ||= 0
    index_count['individual']['index']['id-' + index_point.id.to_s] += index_point_sum
    index_count[:single_index_count] ||= {}
    index_count[:single_index_count][index_point.file_index_id] ||= 0
    index_count[:single_index_count][index_point.file_index_id] += index_point_sum
    session[:count_presence][:index] = true if index_count[index_point.file_index.collection_resource_file_id][single_keyword] > 0 && !session[:count_presence][:index]
    index_count
  end

  def count_description_occurrence(description_point, single_keyword, description_count)
    description_count[single_keyword] ||= 0
    description_count['total'] ||= 0
    this_value_count = count_em(description_point['value'], single_keyword)
    this_vocab_count = count_em(description_point['vocab_value'], single_keyword) if description_point['vocab_value'].present?
    description_count[single_keyword] += this_vocab_count if this_vocab_count
    description_count[single_keyword] += this_value_count if this_value_count

    description_count['total'] += this_vocab_count if this_vocab_count
    description_count['total'] += this_value_count if this_value_count
    session[:count_presence][:description] = true if description_count[single_keyword] > 0 && !session[:count_presence][:description]
    description_count
  end

  def search_text_found_in_files(count_file_wise)
    search_text_found = false
    count_file_wise.each do |index, _value|
      search_text_found = true if (count_file_wise.key? index) && (count_file_wise[index].fetch('total-index', 0) > 0 || count_file_wise[index].fetch('total-transcript', 0) > 0)
    end
    search_text_found
  end

  def ready_keyword_for_count(searched_keywords, document_current, description_search_fields, index_search_fields, transcript_search_fields, other_fields)
    special_keywords = []
    all_keywords = searched_keywords
    if all_keywords
      considered = []
      all_keywords.each do |query_string|
        qoutes_string = query_string.scan(/"([^"]*)"/).flatten
        qoutes_string.each do |single_qouted_string|
          query_string = query_string.gsub('"' + single_qouted_string + '"', '')
        end
        special_keywords << qoutes_string if qoutes_string.present?
        query_string = query_string.delete('"').strip
        special_keywords << query_string if query_string.include? '*'
        special_keywords << query_string.downcase unless considered.include?(query_string.downcase) || stopwords.include?(query_string.to_s.downcase)
        considered << query_string.downcase
      end
    end
    special_keywords = special_keywords.flatten
    counts = {}
    special_keywords.each do |query_string|
      query_string = query_string.delete('"').delete('*').strip
      counts[query_string] ||= {}
      counts[query_string]['Title'] ||= 0
      [description_search_fields, index_search_fields, transcript_search_fields].reduce([], :concat).each do |values|
        title = values.to_s.titleize
        %w[Description Texts Text Search Keywords Subjects Synopsis Subjects Speaker Script Partial Point].each do |single_word|
          title = title.sub! single_word, '' if title.include?(single_word)
        end
        title = title.strip
        counts[query_string][title.to_s] ||= 0
        counts[query_string]['total_custom_keyword'] ||= 0
        unless title.blank?
          if document_current[values].is_a?(Array)
            document_current[values].each do |single_value|
              counts[query_string][title] += count_em(single_value, query_string)
              counts[query_string]['total_custom_keyword'] += count_em(single_value, query_string)
            end
          else
            counts[query_string][title] += count_em(document_current[values], query_string)
            counts[query_string]['total_custom_keyword'] += count_em(document_current[values], query_string)
          end
        end
      end
    end
    if document_current['title_ss'].present?
      counts[query_string]['Title'] += count_em(document_current['title_ss'], query_string)
    end
    counts
  end
end
