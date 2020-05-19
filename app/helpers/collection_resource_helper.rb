# Detail ArchivesSpaceHelper Helper
module CollectionResourceHelper
  def display_field_title_table(value)
    value = value.sub('_search', '')
    if value == 'title_ss'
      custom_value = 'Title'
    elsif value == 'id_ss'
      custom_value = 'Aviary Resource ID'
    elsif value == 'id_is'
      custom_value = 'Aviary Resource ID'
    elsif %w(custom_unique_identifier_ss custom_unique_identifier_texts).include?(value)
      custom_value = 'Custom Unique Identifier'
    else
      custom_value = value.to_s.split('_')
      custom_value[0] = '' unless %w(id_ss title_ss collection_title resource_file_count_ss transcripts_count_ss indexes_count_ss updated_at_ss access_ss).include? value
      custom_value[custom_value.size - 1] = ''
      custom_value = custom_value.join(' ').titleize.strip
      custom_value = 'Public' if custom_value == 'Access'
      custom_value = 'Source Metadata URI' if custom_value == 'Source Metadata Uri'
    end
    custom_value
  end

  def embeded_url(url, action, resource_file_id)
    origin = Addressable::URI.parse(url).origin
    iframe_url = if action == 'embed'
                   origin + '/embed/media/' + resource_file_id.to_s
                 elsif action == 'media_player'
                   origin + '/embed/media/' + resource_file_id.to_s + '?embed=true&media_player=true'
                 else
                   origin + request.env['PATH_INFO'] + '?embed=true'
                 end
    iframe_url
  end
end
