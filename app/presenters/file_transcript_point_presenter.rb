# FileTranscriptPointPresenter
# presenters/file_transcript_point_presenter.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class FileTranscriptPointPresenter < BasePresenter
  def display_time
    Time.at(@model.start_time.to_f).utc.strftime('%H:%M:%S')
  end

  def title_with_timecode
    return if @model.title.blank?
    format('<div class="pb-10px"><a class="play-timecode" href="javascript://" data-timecode="%s">%s</a></div>', @model.start_time, @model.title)
  end

  def show_transcript_point(transcript_time_start_single)
    "<div class='d-flex pt-5px pb-5px transcript_time #{transcript_time_start_single}' id='transcript_timecode_#{id}' data-transcript_timecode='#{start_time.to_i}'>
      <div class='text-center file_transcript_mark_custom timecode_section mr-2 ml-2'>
      <a class='play-timecode' href='javascript://' data-timecode='#{start_time}'>#{display_time.html_safe}</a>
      </div>
      <div class='content_section'>
        <span class='file_transcript_mark_custom'>#{title_with_timecode}</span>
         <div class='file_transcript_mark_custom' data-point='#{id}' data-time='#{start_time}'>#{speaker_with_text}</div>
      </div>
    </div>"
  end

  def speaker_with_text(session_video_text_all = nil)
    font_regex = %r{<font.*?>(.+?)<\/font>}
    if @model.speaker.blank?
      reg_ex = /([A-Z0-9.\' ]+: )/
      return if @model.text.blank?
      text = @model.text.strip.gsub(reg_ex, format('<a class="play-timecode" href="javascript://" data-timecode="%s">\\0</a>', @model.start_time))
      text = text.gsub(/\r\n|\r|\n/, '<br>')
      text = text.gsub(/(<br>)\1/, '<breaktag>').gsub('<br>', ' ')
      text = text.gsub('<breaktag>', '<br><br>').strip
      text = text.gsub(font_regex, '\1')
    else
      text = format('<a class="play-timecode" href="javascript://" data-timecode="%s">%s:</a> %s', @model.start_time, @model.speaker, @model.text.strip.gsub(font_regex, '\1'))
    end
    replacement, text = prep_string_for_markers(text)

    if session_video_text_all.present?
      session_video_text_all.each do |key_keyword, single_keyword|
        text = text.gsub(/(#{single_keyword})/i, '<span data-markjs="true" class="highlight-marker mark ' + key_keyword + '">' + single_keyword + '</span>')
      end
    end

    if replacement.present?
      replacement.each do |key, single_replacement|
        text = text.gsub(/(#{key})/i, single_replacement)
      end
    end

    text
  end

  def prep_string_for_markers(text)
    replacement = {}
    if text.present? && text.scan(/<[^>]*>/).present?
      text.scan(/<[^>]*>/).uniq.each do |single_tag_string|
        random_string_code = random_string(25)
        random_string_code = " --#{random_string_code}-- "
        replacement[random_string_code] = single_tag_string
        text = text.gsub(/(#{single_tag_string})/i, random_string_code)
      end
    end
    [replacement, text]
  end
end
