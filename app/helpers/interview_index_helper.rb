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
      begin
        doc = Nokogiri::HTML(open(interview.media_url.strip, read_timeout: 10))
        video_src_nodes = doc.search('//source')
        video_src_nodes.each do |node|
          source_tags = format('<source src="%s" type="%s"/>', node.attributes['src'].value, video_src_nodes.first.attributes['type'].value)
        end
        data['source_tags'] = source_tags
      rescue StandardError => ex
        Rails.logger.error(ex)
        error = 'Error accessing resource. Please ensure that the resource is public.'
        data['error'] = error
      end

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

      if match.present?
        data['src'] = match[0]
      else
        data['error'] = 'Error processing url. It can be because the provided url is not of vimeo.'
      end
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

    if params[:file_index_point]['zoom'].present? && params[:file_index_point]['gps_latitude'].present? && params[:file_index_point]['gps_description'].present?
      unless params[:file_index_point]['zoom'].first.empty? && params[:file_index_point]['gps_latitude'].first.empty? && params[:file_index_point]['gps_description'].first.empty?
        params[:file_index_point]['gps_latitude'].each_with_index do |gps, _index|
          temp = gps.split(',')
          if temp.length > 1
            lat << temp[0].strip
            long << temp[1].strip
          end
        end
      end
    end

    file_index_point.gps_zoom = params[:file_index_point]['zoom'].to_json if params[:file_index_point]['zoom'].present?
    file_index_point.gps_description = params[:file_index_point]["gps_description#{alt}"].to_json if params[:file_index_point]["gps_description#{alt}"].present?
    file_index_point.gps_latitude = lat.to_json if lat.present?
    file_index_point.gps_longitude = long.to_json if long.present?
    file_index_point.hyperlink = params[:file_index_point]['hyperlink'].to_json if params[:file_index_point]['hyperlink'].present?
    file_index_point.hyperlink_description = params[:file_index_point]["hyperlink_description#{alt}"].to_json if params[:file_index_point]["hyperlink_description#{alt}"].present?
    file_index_point.keywords = params[:keywords].join(';') if params[:keywords].present?
    file_index_point.subjects = params[:subjects].join(';') if params[:subjects].present?
    file_index_point.parent_id = params[:file_index_point][:parent_id] if params[:file_index_point][:parent_id].present?
    file_index_point.publisher = params[:file_index_point][:publisher] if params[:file_index_point][:publisher].present?
    file_index_point.contributor = params[:file_index_point][:contributor] if params[:file_index_point][:contributor].present?
    file_index_point.identifier = params[:file_index_point][:identifier] if params[:file_index_point][:identifier].present?
    file_index_point.rights = params[:file_index_point][:rights] if params[:file_index_point][:rights].present?
    file_index_point.segment_date = params[:file_index_point][:segment_date] if params[:file_index_point][:segment_date].present?
    if params[:file_index_point][:end_time].present? && human_to_seconds(params[:file_index_point][:end_time]).to_f > file_index_point.start_time
      file_index_point.end_time = human_to_seconds(params[:file_index_point][:end_time]).to_f
      return file_index_point
    end

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

  def select_file_index_points(file_index_points, file_index_point)
    if file_index_points.present? && file_index_points.is_a?(Enumerable)
      return file_index_points
    end

    file_index_point.present? && file_index_point.is_a?(Enumerable) ? file_index_point : []
  end

  def render_index_timeline(total_duration, index_points, active_point_id)
    html = ''

    index_points = index_points.sort_by { |t| t.start_time.to_f }
    index_points.each_with_index do |point, index|
      if index == 0 && point.start_time != 0
        width = point.start_time / total_duration * 100
        html += index_segment(index, width, point, true) if width > 0
      end

      index_duration = (point.end_time || index_points[index + 1]&.start_time ||
        total_duration) - point.start_time

      width = index_duration / total_duration * 100
      html += index_segment(index, width, point, false, point.id == active_point_id.to_i)

      next_starting_time = index_points[index + 1]&.start_time || total_duration
      if point.end_time.present? && point.end_time != next_starting_time
        index_duration = next_starting_time - point.end_time
        width = index_duration / total_duration * 100

        html += index_segment(index, width, point, true) if width > 0
      end
    end

    html
  end

  def index_segment(index, width, point, disabled = false, active = false)
    if disabled
      <<-HTML
        <div class="index-segment-disabled bg-secondary"
          style="width: #{width.floor(2)}%;">
        </div>
      HTML
    else
      <<-HTML
        <button class="index-segment border-0 #{'active' if active}"
          data-type="index" tabindex="0"
          data-point="#{point.id}" data-timecode="#{point.start_time}"
          data-toggle="tooltip" data-placement="bottom"
          title="#{Time.at(point.start_time.to_f).utc.strftime('%H:%M:%S') + ' ' + point.title}"
          aria-label="Index segment at #{Time.at(point.start_time.to_f).utc.strftime('%H:%M:%S') + ' titled: ' + point.title}"
          style="width: #{width.round(2) < 1 ? 1 : width.ceil(2)}%;"
          data-target="collapse_#{index}">
        </button>
      HTML
    end
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

  def generate_segments_dropdown(file_index, file_index_point)
    options = file_index.file_index_points.where(parent_id: 0)
                        .where.not(id: file_index_point.id)
                        &.sort_by { |t| t.start_time.to_f }&.map do |point|
      <<-HTML
        <option value="#{point.id}" #{point.id == file_index_point.parent_id ? 'selected' : ''}>#{point.title}</option>
      HTML
    end

    options.join("\n")
  end
end
