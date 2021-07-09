# CollectionResourceFilePresenter
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class CollectionResourceFilePresenter < BasePresenter
  include ApplicationHelper

  def media_url
    if @model.embed_code.present? && @model.embed_type
      @model.embed_code
    else
      expiry = @model.duration.to_f * 2
      @model.resource_file.expiring_url(expiry.ceil)
    end
  end

  def media_type
    if @model.embed_code.present? && @model.embed_type
      @model.embed_content_type
    else
      content_type = @model.resource_file_content_type
      content_type = 'video/mp4' if @model.resource_file_content_type == 'video/quicktime'
      content_type
    end
  end

  def tracks
    tracks = ''
    close_captions = @model.file_transcripts.cc
    return tracks if close_captions.nil?
    default = ''
    close_captions.each_with_index do |cc, index|
      default = 'default' if @model.is_cc_on && index.zero?
      tracks += format('<track label="%s" kind="captions" srclang="%s" src="%s" %s>', languages_array_simple[0].key(cc.language), cc.language, cc.associated_file.url, default)
    end
    tracks
  end

  def embed_source
    return unless @model.embed_code.present? && @model.embed_type
    'embed youtube' if @model.embed_content_type == 'video/youtube'
  end

  def avalon_cls(is_audio_player)
    return 'video_widget' if media_type.include? 'video'
    return 'audio_widget audio-player' if is_audio_player
    'audio_widget'
  end

  def audio_poster(is_audio_only)
    return if is_audio_only
    @model.embed_code.present? ? @model.thumbnail.url : "https://#{ENV['S3_HOST_CDN']}/public/images/audio-default.png"
  end

  def audio_source_tag
    media_type.include?('audio/avalon') ? avalon_m3u8 : format('<source src="%s" type="audio/mp3" />', media_url)
  end

  def video_poster
    return @model.thumbnail.url if media_type.include?('video/avalon') || (@model.embed_code.present? && @model.embed_type.zero?)
    @model.thumbnail.url unless @model.embed_code.present?
  end

  def video_source_tag
    if media_type.include?('video/avalon')
      avalon_m3u8
    elsif @model.embed_code.present? && @model.embed_type.zero?
      format('<source src="%s" type="%s" />', @model.embed_code, media_type)
    else
      format('<source src="%s" type="%s" />', media_url, media_type)
    end
  end

  def avalon_m3u8
    source_tags = ''
    doc = Nokogiri::HTML(open(media_url, read_timeout: 10, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))
    video_src_nodes = doc.search("//source[@type='application/x-mpegURL']")
    video_src_nodes.each do |node|
      source_tags = format('<source src="%s" type="application/x-mpegURL" label="%s"/>', node.attributes['src'].value, node.attributes['data-quality'].value) if node.attributes['data-quality'].value == 'auto'
    end
    source_tags
  end

  def cross_origin_attr
    @model.embed_code.present? && @model.embed_content_type.present? ? '' : 'crossorigin="anonymous"'
  end
end
