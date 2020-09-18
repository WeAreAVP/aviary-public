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
    close_captions.each do |cc|
      tracks += format('<track label="%s" kind="subtitles" srclang="%s" src="%s">', languages_array_simple[0].key(cc.language), cc.language, cc.associated_file.url)
    end
    tracks
  end

  def embed_source
    embed_source = ''
    if @model.embed_code.present? && @model.embed_type
      if @model.embed_content_type == 'video/youtube'
        embed_source = 'embed youtube'
      elsif @model.embed_content_type == 'video/vimeo'
        embed_source = 'embed vimeo'
      end
    end
    embed_source
  end
end
