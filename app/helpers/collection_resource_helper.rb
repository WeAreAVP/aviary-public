# Detail CollectionResourceHelper Helper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module CollectionResourceHelper
  def display_field_title_table(value)
    value = value.sub('_search', '')
    if value == 'title_ss'
      custom_value = 'Title'
    elsif value == 'id_ss'
      custom_value = 'Aviary Resource ID'
    elsif value == 'id_is'
      custom_value = 'Aviary Resource ID'
    elsif value == 'resource_file_count_ss'
      custom_value = 'Media File Count'
    elsif value == 'supplemental_file_count_ss'
      custom_value = 'Supplemental File Count'
    elsif value.include?('custom_field_values_')
      custom_value = value.gsub('custom_field_values_', '')
      custom_value = Aviary::SolrIndexer.remove_field_type_string(custom_value)
      custom_value = custom_value.titleize.strip
    elsif %w(custom_unique_identifier_ss custom_unique_identifier_texts).include?(value)
      custom_value = 'Custom Unique Identifier'
    else
      custom_value = value.to_s.split('_')
      unless %w(id_ss title_ss collection_title supplemental_file_count_ss resource_file_count_ss transcripts_count_ss
                indexes_count_ss updated_at_ss access_ss collection_sort_order_ss).include? value

        custom_value[0] = ''
      end

      custom_value[custom_value.size - 1] = ''
      custom_value = custom_value.join(' ').titleize.strip
      custom_value = 'Public' if custom_value == 'Access'
      custom_value = 'Source Metadata URI' if custom_value == 'Source Metadata Uri'
      custom_value = value unless custom_value.present?
    end
    custom_value
  end

  def append_param_to_url(keywords, url, skip_keyword = false)
    if keywords.present?
      url += '?u=t' unless url.include?('?')
      keywords.each do |single_keyword|
        next if skip_keyword && skip_keyword == single_keyword
        url += "&keywords[]=#{single_keyword}"
      end
    end
    url = url.gsub('&&', '&')
    url = url.delete('"')
    url
  end

  def embeded_url(url, action, resource_file_id)
    origin = Addressable::URI.parse(url).origin
    iframe_url = if action == 'embed'
                   origin + '/embed/media/' + (resource_file_id.present? ? resource_file_id.to_s : '')
                 elsif action == 'media_player'
                   origin + '/embed/media/' + (resource_file_id.present? ? resource_file_id.to_s : '') + '?embed=true&media_player=true'
                 else
                   origin + request.env['PATH_INFO'] + '?embed=true'
                 end
    iframe_url
  end

  def string_hash_to_hash(ruby_hash_text)
    # Transform object string symbols to quoted strings
    ruby_hash_text.gsub!(/([{,]\s*):([^>\s]+)\s*=>/, '\1"\2"=>')

    # Transform object string numbers to quoted strings
    ruby_hash_text.gsub!(/([{,]\s*)([0-9]+\.?[0-9]*)\s*=>/, '\1"\2"=>')

    # Transform object value symbols to quotes strings
    ruby_hash_text.gsub!(/([{,]\s*)(".+?"|[0-9]+\.?[0-9]*)\s*=>\s*:([^,}\s]+\s*)/, '\1\2=>"\3"')

    # Transform array value symbols to quotes strings
    ruby_hash_text.gsub!(/([\[,]\s*):([^,\]\s]+)/, '\1"\2"')

    # Transform object string object value delimiter to colon delimiter
    ruby_hash_text.gsub!(/([{,]\s*)(".+?"|[0-9]+\.?[0-9]*)\s*=>/, '\1\2:')

    JSON.parse(ruby_hash_text)
  end
end
