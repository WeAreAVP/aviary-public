# InterviewIndexHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module InterviewIndexHelper
  def interview_video_info_helper(interview)
    data = {}
    data['type'] = 'video/' + interview.media_host.downcase
    if interview.media_host == 'Kaltura'
      regex = %r{/p/([0-9]+)/}
      match = regex.match(interview.embed_code)
      data['partner_id'] = match[1]

      regex = %r{/uiconf_id/([0-9]+)/}
      match = regex.match(interview.embed_code)
      data['uiconf_id'] = match[1]

      regex = /\&entry_id=(.*?)\&/
      match = regex.match(interview.embed_code)
      data['entry_id'] = match[1]

      regex = %r{https?\://[^/]+}
      match = regex.match(interview.embed_code)
      data['kaltura_url'] = match[0]

    elsif interview.media_host == 'Avalon'
      regex = /src="([^"]+)"/
      match = regex.match(interview.embed_code)

      source_tags = ''
      doc = Nokogiri::HTML(open(match[1], read_timeout: 10))
      video_src_nodes = doc.search("//source[@type='application/x-mpegURL']")
      video_src_nodes.each do |node|
        source_tags = format('<source src="%s" type="application/x-mpegURL" label="%s"/>', node.attributes['src'].value, node.attributes['data-quality'].value) if node.attributes['data-quality'].value == 'auto'
      end
      data['source_tags'] = source_tags

    elsif interview.media_host == 'Other'
      ext = File.extname(URI.parse(URI::Parser.new.escape(interview.media_url)).to_s)
      data['type'] = if interview.media_format == 'audio'
                       "audio/#{ext.sub('.', '')}"
                     else
                       "video/#{ext.sub('.', '')}"
                     end
      if data['type'].include?('audio/m4a')
        data['type'] = data['type'].gsub('m4a', 'mp4')
      end
      data['src'] = interview.media_url

    elsif interview.media_host == 'Aviary'
      source_tags = ''
      doc = Nokogiri::HTML(open(interview.media_url.strip, read_timeout: 10))
      video_src_nodes = doc.search('//source')
      video_src_nodes.each do |node|
        source_tags = format('<source src="%s" type="%s"/>', node.attributes['src'].value, video_src_nodes.first.attributes['type'].value)
      end
      data['source_tags'] = source_tags

    elsif interview.media_host == 'SoundCloud'
      data['iframe'] = interview.embed_code.sub('<iframe ', '<iframe id="soundcloud_widget" ')

    elsif interview.media_host == 'Brightcove'
      data['account'] = interview.media_host_account_id
      data['player'] = interview.media_host_player_id
      data['video_id'] = interview.media_host_item_id
    elsif interview.media_host == 'YouTube'
      data['src'] = interview.media_url
    elsif interview.media_host == 'Vimeo'
      regex = %r{https?:\/\/(?:\w+\.)*vimeo\.com(?:[\/\w]*\/?)?\/(?<id>[0-9]+)[^\s]*}
      match = regex.match(interview.embed_code)
      data['src'] = "https://player.vimeo.com/video/#{match[1]}"
    end
    data
  end

  def interview_lang_info_helper(language)
    if language.length > 2
      temp = languages_array_simple[0].find { |_i, value| value == language }
      if language == 'Undefined' || temp.nil?
        'un'
      elsif temp.length.positive?
        temp.first
      else
        'en'
      end
    elsif language.length.positive?
      if languages_array_simple[0][language].present?
        language
      else
        'en'
      end
    else
      'en'
    end
  end

  def update_end_time(file_index_point)
    find_previous_file_index_point = FileIndexPoint.where(file_index_id: file_index_point.file_index_id).where('start_time < ?', file_index_point.start_time.to_f).sort_by { |t| t.start_time.to_f }
    find_next_file_index_point = FileIndexPoint.where(file_index_id: file_index_point.file_index_id).where('start_time > ?', file_index_point.start_time.to_f).sort_by { |t| t.start_time.to_f }
    if find_previous_file_index_point.length.positive? && find_next_file_index_point.length.positive?
      last_index_point = FileIndexPoint.find(find_previous_file_index_point.last.id)
      last_index_point.end_time = find_next_file_index_point.first.start_time.to_f
      last_index_point.duration = last_index_point.end_time.to_f - last_index_point.start_time.to_f
      last_index_point.save
    elsif find_previous_file_index_point.length.positive?
      last_index_point = FileIndexPoint.find(find_previous_file_index_point.last.id)
      last_index_point.end_time = file_index_point.end_time.to_f
      last_index_point.duration = last_index_point.end_time.to_f - last_index_point.start_time.to_f
      last_index_point.save
    end
    file_index_point.destroy
  end

  def set_custom_values(file_index_point, alt, params)
    lat = []
    long = []
    unless params[:file_index_point]['zoom'].first.empty? && params[:file_index_point]['gps_latitude'].first.empty? && params[:file_index_point]['gps_description'].first.empty?
      params[:file_index_point]['gps_latitude'].each_with_index do |gps, _index|
        temp = gps.split(',')
        if temp.length > 1
          lat << temp[0].strip
          long << temp[1].strip
        end
      end
    end

    file_index_point.gps_zoom = params[:file_index_point]['zoom'].to_json
    file_index_point.gps_description = params[:file_index_point]["gps_description#{alt}"].to_json
    file_index_point.gps_latitude = lat.to_json
    file_index_point.gps_longitude = long.to_json
    file_index_point.hyperlink = params[:file_index_point]['hyperlink'].to_json
    file_index_point.hyperlink_description = params[:file_index_point]["hyperlink_description#{alt}"].to_json
    file_index_point.subjects = params[:subjects].join(';') if params[:subjects].present?
    file_index_point.keywords = params[:keywords].join(';') if params[:keywords].present?

    set_end_time(file_index_point, params[:item_length].to_f)
  end

  def set_end_time(file_index_point, item_length = 0)
    find_file_index_point = FileIndexPoint.where(file_index_id: file_index_point.file_index_id).where('start_time > ?', file_index_point.start_time.to_f).sort_by { |t| t.start_time.to_f }
    file_index_point.end_time = if find_file_index_point.length.positive?
                                  find_file_index_point.first.start_time.to_f
                                elsif item_length == 0
                                  file_index_point.start_time.to_f
                                else
                                  item_length.to_f
                                end
    file_index_point.duration = file_index_point.end_time.to_f - file_index_point.start_time.to_f

    find_previous_file_index_point = FileIndexPoint.where(file_index_id: file_index_point.file_index_id).where('start_time < ?', file_index_point.start_time.to_f).sort_by { |t| t.start_time.to_f }
    if find_previous_file_index_point.length.positive?
      last_index_point = FileIndexPoint.find(find_previous_file_index_point.last.id)
      last_index_point.end_time = file_index_point.start_time.to_f
      last_index_point.duration = last_index_point.end_time.to_f - last_index_point.start_time.to_f
      last_index_point.save
    end

    file_index_point
  end

  def adjacent_index_points
    next_index_point = previous_index_point = nil

    @file_index_points ||= FileIndexPoint.where(file_index_id: @interview.file_indexes&.first&.id)
    @file_index_points = @file_index_points.sort_by { |t| t.start_time.to_f }
    @file_index_points.each_with_index do |index_point, index|
      if @file_index_point.id == index_point.id
        next_index_point = index < (@file_index_points.length - 1) ? @file_index_points[index + 1] : nil
        previous_index_point = index > 0 ? @file_index_points[index - 1] : nil

        break
      end
    end

    [previous_index_point, next_index_point]
  end
end
