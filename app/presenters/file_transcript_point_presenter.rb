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
    "<div class='row pt-5px pb-5px transcript_time #{transcript_time_start_single}' id='transcript_timecode_#{id}' data-transcript_timecode='#{start_time.to_i}'>
      <div class='col-md-2 text-center file_transcript_mark_custom timecode_section mr-2 ml-2'>
      <a class='play-timecode' href='javascript://' data-timecode='#{start_time}'>#{display_time.html_safe}</a>
      </div>
      <div class='col-md-10 content_section'>
        <span class='file_transcript_mark_custom'>#{title_with_timecode}</span>
         <div class='file_transcript_mark_custom'>#{speaker_with_text}</div>
      </div>
    </div>"
  end

  def speaker_with_text
    font_regex = %r{<font.*?>(.+?)<\/font>}
    if @model.speaker.blank?
      reg_ex = /([A-Z0-9.\' ]+: )/
      return if @model.text.blank?
      text = @model.text.strip.gsub(reg_ex, format('<a class="play-timecode" href="javascript://" data-timecode="%s">\\0</a>', @model.start_time))
      text = text.gsub(/\r\n|\r|\n/, '<br>')
      text = text.gsub(/(<br>)\1/, '<breaktag>').gsub('<br>', ' ')
      text = text.gsub('<breaktag>', '<br><br>').strip
      text.gsub(font_regex, '\1')
    else
      format('<a class="play-timecode" href="javascript://" data-timecode="%s">%s:</a> %s', @model.start_time, @model.speaker, @model.text.strip.gsub(font_regex, '\1'))
    end
  end
end
