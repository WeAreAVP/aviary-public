# services/aviary/extract_video_metadata.rb
#
# Module Aviary::ExtractVideoMetaData
# The module is written to get the metadata of the video from the embed code
# Currently supports Youtube, Vimeo, and SoundCloud
# video_info gem is needed to successfully process the embed code for Youtube and Vimeo
# soundcloud gem is needed to successfully process the embed code for the SoundCloud
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary::ExtractVideoMetadata
  # VideoEmbed Class helps to get the metadata from the embed code
  class VideoEmbed
    mattr_accessor :embed_type
    mattr_accessor :video_embed
    mattr_accessor :params

    def initialize(embed_type, video_embed, params = {})
      self.embed_type = embed_type.delete(' ').humanize
      self.video_embed = video_embed
      self.params = params
    end

    def metadata
      klass_obj = self.class.module_parent.const_get(embed_type).new
      klass_obj.metadata(video_embed)
    end
  end

  # Other Class is to support general iframe embed codes
  class Localmediaserver < VideoEmbed
    def initialize; end

    def metadata(video_embed)
      uri = URI.parse(video_embed)
      metadata = {}
      metadata['url'] = video_embed
      metadata['title'] = params[:title].present? ? params[:title] : File.basename(uri.path)
      metadata['duration'] = params[:duration].to_d
      metadata['content_type'] = Rack::Mime::MIME_TYPES[File.extname(uri.path)].present? ? Rack::Mime::MIME_TYPES[File.extname(uri.path)] : 'video/mp4'
      metadata['thumbnail'] = if params[:thumbnail].present?
                                params[:thumbnail]
                              else
                                metadata['content_type'].include?('audio') ? "https://#{ENV.fetch('S3_HOST_CDN')}/public/images/audio-default.png" : "https://#{ENV.fetch('S3_HOST_CDN')}/public/images/video-default.png"
                              end
      metadata
    end
  end

  # Youtube Class helps to get the url and metadata of the video
  # Make sure to set YOUTUBE_API_KEY variable in your environment
  class Youtube < VideoEmbed
    mattr_accessor :host

    def initialize
      VideoInfo.provider_api_keys = { youtube: ENV.fetch('YOUTUBE_API_KEY', nil) }
      self.host = 'https://www.youtube.com/watch?v='
    end

    def url_from_embed(video_embed)
      regex = %r{(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)}
      match = regex.match(video_embed)
      return if match.nil?
      return if match.size < 6
      "#{host}#{match[5]}"
    end

    def metadata(video_embed)
      video_url = url_from_embed(video_embed)
      return false unless video_url
      metadata = {}
      video = VideoInfo.new(video_url)
      metadata['url'] = video.url
      metadata['duration'] = video.duration
      metadata['title'] = video.title
      metadata['thumbnail'] = video.thumbnail
      metadata['content_type'] = 'video/youtube'
      metadata
    end
  end

  # Vimeo Class helps to get the url and metadata of the video
  # Make sure to set VIMEO_API_KEY variable in your environment
  class Vimeo < VideoEmbed
    include DeprecatedHelper
    mattr_accessor :host

    def initialize
      VideoInfo.provider_api_keys = { vimeo: ENV.fetch('VIMEO_API_KEY', nil) }
      self.host = 'https://player.vimeo.com/video/'
    end

    def url_from_embed(video_embed)
      regex = %r{https?:\/\/(?:\w+\.)*vimeo\.com(?:[\/\w]*\/?)?\/(?<id>[0-9]+)[^\s]*}
      match = regex.match(video_embed)
      return if match.nil?
      return if match.size < 2
      "#{host}#{match[1]}"
    end

    def metadata(video_embed)
      video_url = url_from_embed(video_embed)
      return false unless video_url
      metadata = {}
      video = VideoInfo.new(video_url)
      metadata['url'] = video.url
      metadata['duration'] = 0
      metadata['title'] = ''
      metadata['thumbnail'] = ''
      begin
        metadata['duration'] = video.duration
        metadata['title'] = video.title
        metadata['thumbnail'] = video.thumbnail
      rescue StandardError
        begin
          doc = Nokogiri::HTML(open(video_url, read_timeout: 10))
          metadata['title'] = doc.search('//title')[0].children[0].text
          complex_text = doc.search('//script')[2].children
          valid_metadata = parse_html(complex_text, 'var config =')
          unless valid_metadata.present?
            complex_text = doc.search('//script')[2].children
            valid_metadata = parse_html(complex_text, 'window.playerConfig =')
          end
          unless valid_metadata.present?
            complex_text = doc.search('//script')[3].children
            valid_metadata = parse_html(complex_text, 'window.playerConfig =')
          end
          if valid_metadata.present?
            metadata['title'] = valid_metadata['video']['title']
            metadata['duration'] = valid_metadata['video']['duration']
            metadata['thumbnail'] = valid_metadata['video']['thumbs']['640']
          end
        rescue StandardError
          return false
        end
      end
      metadata['content_type'] = 'video/vimeo'
      metadata
    end

    def parse_html(html, splitter)
      single_line_string = html[0].text.split("\n")
      valid_metadata = nil
      single_line_string.each do |line|
        next if line.blank?
        begin
          clean_line = line.split(splitter)[1].split(';')[0]
          ruby_hash = JSON.parse(clean_line)
          valid_metadata = ruby_hash
          break
        rescue JSON::ParserError
          next
        rescue StandardError
          next
        end
      end
      valid_metadata
    end
  end

  # SoundCloud Class helps to get the url and metadata of the video
  # Make sure to set SOUNDCLOUD_CLIENT_ID variable in your environment
  class Soundcloud < VideoEmbed
    mattr_accessor :host

    def initialize
      self.host = 'https://api.soundcloud.com/tracks/'
    end

    def url_from_embed(video_embed)
      regex = %r{https?:\/\/(?:w\.|www\.|)(?:soundcloud\.com\/)(?:(?:player\/\?url=https\%3A\/\/api.soundcloud.com\/tracks\/)|)(((\w|-)[^A-z]{8})|([A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*(?!\/sets(?:\/|$))(?:\/[A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*){1,2}))}
      match = regex.match(video_embed)
      return if match.nil?
      return if match.size < 2
      secret_token_str = CGI.unescape(video_embed).split('secret_token=')
      secret_token = secret_token_str.size == 2 ? '?secret_token=' + secret_token_str.last.split('&').first : ''
      "#{host}#{match[1]}#{secret_token}"
    end

    def metadata(video_embed)
      video_url = url_from_embed(video_embed)
      return false unless video_url
      client = SoundCloud.new(client_id: ENV.fetch('SOUNDCLOUD_CLIENT_ID', nil))
      begin
        track = client.get('/resolve', url: video_url)
        metadata = {}
        uri = URI.parse(track.stream_url)
        param_operator = uri.query.present? ? '&' : '?'
        metadata['url'] = "#{track.stream_url}#{param_operator}client_id=#{ENV.fetch('SOUNDCLOUD_CLIENT_ID', nil)}"
        metadata['duration'] = track.duration.to_f / 1000 # convert milliseconds to seconds
        metadata['title'] = track.title
        metadata['thumbnail'] = track.artwork_url
        metadata['content_type'] = 'audio/mp3'
        metadata
      rescue StandardError
        false
      end
    end
  end

  # Avalon Class helps to get the metadata of the video
  class Avalon < VideoEmbed
    include DeprecatedHelper
    def initialize; end

    def url_from_embed(video_embed)
      regex = /src="([^"]+)"/
      match = regex.match(video_embed)
      return if match.nil?
      return if match.size < 2
      media_url = match[1]
      if media_url.include?(':443')
        media_url = media_url.gsub(':443', '')
        media_url = media_url.gsub('//', 'https://')
      end
      media_url
    end

    def metadata(video_embed)
      video_url = url_from_embed(video_embed)
      return false unless video_url
      metadata = {}
      begin
        doc = Nokogiri::HTML(open(video_url, read_timeout: 10))
        title_node = doc.search("//meta[@itemprop='name']")
        thumbnail_node = doc.search("//meta[@itemprop='image']")
        duration_node = doc.search("//meta[@itemprop='duration']")
        media_type_node = doc.search("//div[@itemscope='itemscope']")
        title = title_node[0].attributes['content'].value if title_node.present?
        thumbnail = thumbnail_node[0].attributes['content'].value if thumbnail_node.present?
        duration = duration_node[0].attributes['content'].value.to_f if duration_node.present?
        media_type = media_type_node[0].attributes['itemprop'].value if media_type_node.present?
        metadata['url'] = video_url
        metadata['duration'] = duration
        metadata['title'] = title
        metadata['thumbnail'] = thumbnail
        metadata['content_type'] = "#{media_type}/avalon"
        metadata
      rescue StandardError
        false
      end
    end
  end
end
