# Detail Page Helper
module DetailPageHelper
  def count_occurrence(point, session_video_text, type_count, type, is_file_wise = false, counter = nil, annotation_search_count = nil, all_annotations = nil, sub_type = nil)
    return type_count if session_video_text.blank?
    session_video_text.each do |_, single_keyword|
      unless single_keyword.blank?
        single_keyword = single_keyword.delete '"'
        if type == 'transcript'
          type_count, annotation_search_count = count_transcript_occurrence(point, single_keyword, type_count, is_file_wise, counter, annotation_search_count, all_annotations)
        elsif type == 'index'
          type_count = count_index_occurrence(point, single_keyword, type_count, is_file_wise, counter)
        elsif type == 'description'
          type_count = count_description_occurrence(point, single_keyword, type_count, sub_type)
        end
      end
    end
    type == 'transcript' ? [type_count, annotation_search_count] : type_count
  end

  def add_loader(extra_class)
    image_link = "https://#{ENV['S3_HOST_CDN']}/public/images/ajax-loader.gif"
    "<div class='#{extra_class}'>
      <div class='img'>
        <div class='hold'>#{image_tag(image_link)}
        </div>
      </div>
    </div>".html_safe
  end

  def count_transcript_occurrence(transcript_point, single_keyword, transcript_count, is_file_wise, counter, annotation_search_count, _all_annotations)
    transcript_point_sum = count_em(transcript_point.text, single_keyword) + count_em(transcript_point.speaker, single_keyword)
    transcript_count[transcript_point.file_transcript.collection_resource_file_id] ||= {}
    transcript_count[transcript_point.file_transcript.collection_resource_file_id]['total-transcript'] ||= 0
    transcript_count[transcript_point.file_transcript.collection_resource_file_id]['total-transcript'] += transcript_point_sum
    return transcript_count if is_file_wise
    hash_keyword = key_hash_manager(single_keyword)

    transcript_count[transcript_point.file_transcript.collection_resource_file_id][single_keyword] ||= 0
    transcript_count[transcript_point.file_transcript.collection_resource_file_id][single_keyword] += transcript_point_sum
    transcript_count['individual'] ||= {}
    transcript_count['individual']['transcript'] ||= {}
    transcript_count['individual']['transcript']['id-' + transcript_point.id.to_s] ||= 0
    transcript_count['individual']['transcript']['id-' + transcript_point.id.to_s] += transcript_point_sum

    transcript_count[:single_transcript_count] ||= {}
    transcript_count[:single_transcript_count][transcript_point.file_transcript_id] ||= 0
    transcript_count[:single_transcript_count][transcript_point.file_transcript_id] += transcript_point_sum

    transcript_count[:hits] ||= {}
    transcript_count[:hits][transcript_point.file_transcript_id] ||= {}
    transcript_count[:hits][transcript_point.file_transcript_id][hash_keyword] ||= []

    annotation_search_count ||= {}

    if counter.present?

      transcript_count[:page_wise] ||= {}
      transcript_count[:page_wise][:transcript] ||= {}
      transcript_count[:page_wise][:transcript][transcript_point.file_transcript_id] ||= {}
      current_page = (counter / Aviary::IndexTranscriptManager::POINTS_PER_PAGE).floor
      transcript_count[:page_wise][:transcript][transcript_point.file_transcript_id][current_page] ||= 0
      transcript_count[:page_wise][:transcript][transcript_point.file_transcript_id][current_page] += transcript_point_sum

      transcript_count[:total_transcript_wise] ||= {}
      transcript_count[:total_transcript_wise][transcript_point.file_transcript_id] ||= {}
      transcript_count[:total_transcript_wise][transcript_point.file_transcript_id][hash_keyword] ||= 0
      transcript_count[:total_transcript_wise][transcript_point.file_transcript_id][hash_keyword] += transcript_point_sum
      all_marker_occurrences_point = transcript_point.text.match_all(single_keyword, "transcript_timecode_#{transcript_point.id}")
      all_hits = all_marker_occurrences_point
      x = 0
      all_hits.each do |_key, single_hit|
        if single_hit.class == Array
          inner_increment = 0
          single_hit.each do |single_hit_level_one|
            transcript_count[:hits][transcript_point.file_transcript_id][hash_keyword] << "#{single_hit_level_one}||#{inner_increment}||#{current_page}"
            inner_increment += 1
          end
        else
          transcript_count[:hits][transcript_point.file_transcript_id][hash_keyword] << "#{single_hit}||#{x}||#{current_page}"
          x += 1
        end
      end
    end
    [transcript_count, annotation_search_count]
  end

  def annotation_search_count_init(collection_resource_file_id, annotation_search_count, transcript_id, hash_keyword, transcript_id_point_id)
    annotation_search_count[collection_resource_file_id] ||= {}
    annotation_search_count[collection_resource_file_id][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:annotation_wise] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:annotation_wise][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_set_wise][:total] ||= 0
    annotation_search_count[collection_resource_file_id][:total_set_wise][:annotation_set_id] ||= {}
    annotation_search_count
  end

  def count_handler_annotations(annotation_search_count, collection_resource_file_id, transcript_id, annotation_point_sum, hash_keyword, single_annotation_point, transcript_id_point_id)
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][:total] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:total] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:annotation_wise][:total] += annotation_point_sum

    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id] ||= {}
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:annotation_wise][single_annotation_point.id] ||= 0
    annotation_search_count[collection_resource_file_id][:total_transcript_wise][transcript_id][hash_keyword][:total_transcript_point_wise][transcript_id_point_id][:annotation_wise][single_annotation_point.id] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total_set_wise][:total] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total_set_wise][:annotation_set_id][single_annotation_point.annotation_set_id] ||= 0
    annotation_search_count[collection_resource_file_id][:total_set_wise][:annotation_set_id][single_annotation_point.annotation_set_id] += annotation_point_sum
    annotation_search_count[collection_resource_file_id][:total] += annotation_point_sum
    annotation_search_count
  end

  def self.count_annotation_occurrence(transcript_id, annotation_count)
    annotation_count ||= {}
    current_page = 0
    annotation_count[:hits] ||= {}
    annotation_count[:hits][:total] ||= {}
    annotations = Annotation.where(target_content_id: transcript_id).order('target_sub_id ASC')

    if annotations.present?
      sorted_annotations = {}
      annotations.each do |single_annotation|
        sorted_annotations[single_annotation.target_sub_id] ||= {}
        target_info = JSON.parse(single_annotation.target_info)
        sorted_annotations[single_annotation.target_sub_id][target_info['startOffset']] = single_annotation
      end
      sorted_annotations = Hash[sorted_annotations.sort]
      sorted_annotations.each do |_index, single_annotation|
        counter = 0
        single_annotation = Hash[single_annotation.sort]
        single_annotation.each do |_index, single_annotation_point|
          annotation_count[:hits][transcript_id] ||= []
          annotation_count[:annotation_ids] ||= {}
          annotation_count[:annotation_ids][single_annotation_point.target_content_id] ||= []
          annotation_count[:hits][single_annotation_point.target_content_id] << "transcript_timecode_#{single_annotation_point.target_sub_id}||#{counter}||#{current_page}||#{single_annotation_point.id}"
          annotation_count[:annotation_ids][single_annotation_point.target_content_id] << single_annotation_point.id
          counter += 1
        end
      end
    end
    annotation_count[:hits][:total][transcript_id] = Annotation.where(target_content_id: transcript_id).count
    annotation_count
  end

  def count_index_occurrence(index_point, single_keyword, index_count, is_file_wise, counter)
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

    if counter.present?
      index_count[:page_wise] ||= {}
      index_count[:page_wise][:index] ||= {}
      index_count[:page_wise][:index][index_point.file_index_id] ||= {}
      current_page = (counter / Aviary::IndexTranscriptManager::POINTS_PER_PAGE).floor
      index_count[:page_wise][:index][index_point.file_index_id][current_page] ||= 0
      index_count[:page_wise][:index][index_point.file_index_id][current_page] += index_point_sum

      index_count[:hits] ||= {}
      index_count[:hits][index_point.file_index_id] ||= {}
      hash_keyword_index = key_hash_manager(single_keyword)
      index_count[:hits][index_point.file_index_id][hash_keyword_index] ||= []

      index_count[:total_index_wise] ||= {}
      index_count[:total_index_wise][index_point.file_index_id] ||= {}
      hash_keyword_index_inner = key_hash_manager(single_keyword)
      index_count[:total_index_wise][index_point.file_index_id][hash_keyword_index_inner] ||= 0
      index_count[:total_index_wise][index_point.file_index_id][hash_keyword_index_inner] += index_point_sum

      x = 0
      while x < index_point_sum
        index_count[:hits][index_point.file_index_id][hash_keyword_index_inner] << "index_timecode_#{index_point.id}||#{x}||#{current_page}"
        x += 1
      end
    end
    index_count
  end

  def count_description_occurrence(description_point, single_keyword, description_count, type)
    description_count[single_keyword] ||= 0
    description_count['total'] ||= 0
    description_count[type] ||= 0
    this_value_count = count_em(description_point['value'], single_keyword)
    this_vocab_count = count_em(description_point['vocab_value'], single_keyword) if description_point['vocab_value'].present?
    description_count[single_keyword] += this_vocab_count if this_vocab_count
    description_count[single_keyword] += this_value_count if this_value_count
    description_count['total'] += this_vocab_count if this_vocab_count
    description_count['total'] += this_value_count if this_value_count
    description_count[type] += this_vocab_count if this_vocab_count
    description_count[type] += this_value_count if this_value_count
    session[:count_presence][:description] = true if description_count[single_keyword] > 0 && !session[:count_presence][:description]
    description_count
  end

  def search_text_found_in_files(count_file_wise)
    search_text_found = false
    count_file_wise.each do |index, _value|
      search_text_found = true if (count_file_wise.key? index) && (count_file_wise[index].fetch('total_index', 0) > 0 || count_file_wise[index].fetch('total_transcript', 0) > 0)
    end
    search_text_found
  end

  def index_page_wise_time_range(index_count_time_range, index_point, counter)
    current_page = (counter / Aviary::IndexTranscriptManager::POINTS_PER_PAGE).floor
    index_count_time_range ||= {}
    index_count_time_range[index_point.file_index_id] ||= {}
    index_count_time_range[index_point.file_index_id][current_page + 1] ||= {}
    index_count_time_range[index_point.file_index_id][current_page + 1][:start_time] ||= 0
    index_count_time_range[index_point.file_index_id][current_page + 1][:end_time] ||= 0
    index_count_time_range[index_point.file_index_id][current_page + 1][:start_time] = index_point.start_time unless index_count_time_range[index_point.file_index_id][current_page + 1][:start_time] > 0
    index_count_time_range[index_point.file_index_id][current_page + 1][:end_time] = index_point.end_time
    index_count_time_range[index_point.file_index_id][current_page + 1][:current_page] = current_page + 1
    index_count_time_range
  end

  def transcript_page_wise_time_range(transcript_count_time_range, transcript_point, counter)
    current_page = (counter / Aviary::IndexTranscriptManager::POINTS_PER_PAGE).floor
    transcript_count_time_range ||= {}
    transcript_count_time_range[transcript_point.file_transcript_id] ||= {}
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1] ||= {}
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:start_time] ||= 0
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:end_time] ||= 0
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:start_time] = transcript_point.start_time unless transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:start_time] > 0
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:end_time] = transcript_point.end_time
    transcript_count_time_range[transcript_point.file_transcript_id][current_page + 1][:current_page] = current_page + 1
    transcript_count_time_range
  end

  def ready_keyword_for_count(searched_keywords, document_current, description_search_fields, index_search_fields, transcript_search_fields)
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
        if !query_string.include?('"') && query_string.include?(' ')
          more_term = SearchBuilder.term_divider(query_string)
          more_term.each do |single_terms|
            special_keywords << single_terms.downcase unless considered.include?(single_terms.downcase) || stopwords.include?(single_terms.to_s.downcase)
            considered << single_terms.downcase
          end
        else
          special_keywords << query_string.downcase unless considered.include?(query_string.downcase) || stopwords.include?(query_string.to_s.downcase)
          considered << query_string.downcase
        end
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
        %w[Description Texts Text Search Keywords Subjects Synopsis Subjects Speaker Script Partial Point Body Content].each do |single_word|
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
      if document_current['title_ss'].present?
        counts[query_string]['Title'] += count_em(document_current['title_ss'], query_string)
      end
    end
    counts
  end
end
