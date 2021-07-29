# FileTranscriptPointPresenter
# presenters/file_transcript_point_presenter.rb
#
# Use ::Kernel.binding.pry for debug
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileTranscriptPointPresenter < BaseIndexTranscriptPresenter
  delegate :can?, to: :h
  include DetailPageHelper
  include ApplicationHelper

  def count_annotation_occurrence_present(transcript_id, annotation_count)
    DetailPageHelper.count_annotation_occurrence(transcript_id, annotation_count)
  end

  def display_time
    Time.at(@model.start_time.to_f).utc.strftime('%H:%M:%S')
  end

  def title_with_timecode
    return if @model.title.blank?
    format('<div class="pb-10px"><a class="play-timecode" href="javascript://" data-timecode="%s">%s</a></div>', @model.start_time, @model.title)
  end

  def show_transcript_point(transcript_time_start_single, can_access_annotation, annotation_search_count = nil, session_video_text_all = nil)
    "<div class='d-flex pt-5px pb-5px transcript_time #{transcript_time_start_single}' id='transcript_timecode_#{id}' data-transcript_timecode='#{start_time.to_i}'>
      <div class='text-center file_transcript_mark_custom timecode_section mr-2 ml-2'>
      <a class='play-timecode' href='javascript://' data-timecode='#{start_time}'>#{display_time.html_safe}</a>
      </div>
      <div class='content_section'>
        <span class='file_transcript_mark_custom'>#{title_with_timecode}</span>
         <div class='file_transcript_mark_custom' data-point='#{id}' data-time='#{start_time}'>#{speaker_with_text(can_access_annotation, annotation_search_count, session_video_text_all)}</div>
      </div>
    </div>"
  end

  def append_annotation(text, can_access_annotation, speaker_text = 0, annotation_search_count = {}, session_video_text_all = {})
    return text unless @model.file_transcript.annotation_set.present? && can_access_annotation
    text = text.force_encoding('UTF-8')
    annotations = @model.file_transcript.annotation_set.annotations.where(target_content: FileTranscript.to_s).where(target_sub_id: @model.id)
    text_to_replace = {}
    annotations.each_with_index do |annotation, key|
      target_info = JSON.parse(annotation.target_info)
      start_offset = target_info['startOffset'] - speaker_text
      length = target_info['endOffset'] - target_info['startOffset']
      replace = key.to_s * length
      next if start_offset + length > text.size
      text_to_replace[replace] = text[start_offset, length]
      text[start_offset, length] = replace
    end
    annotations.each_with_index do |annotation, key|
      hit_by_search = ''
      collection_resource_file_id = @model.file_transcript.collection_resource_file_id
      file_transcript_id = @model.file_transcript_id
      session_video_text_all.each do |key_keyword, _single_keyword|
        number_of_hits = if annotation_search_count.present?
                           begin
                             annotation_search_count[collection_resource_file_id][:total_transcript_wise][file_transcript_id][key_keyword][:total_transcript_point_wise][id][:annotation_wise][annotation.id]
                           rescue StandardError
                             0
                           end
                         end
        hit_by_search += " data-annotation-hit-search-#{key_keyword}=\"#{number_of_hits}\" "
      end

      target_info = JSON.parse(annotation.target_info)
      length = target_info['endOffset'] - target_info['startOffset']
      replace = key.to_s * length
      element = '<div class="flag annotation_flag annotation_' + annotation.id.to_s + '" data-annotation="' + annotation.id.to_s + '"><div class="line"></div></div>' \
                '<span data-annotation="' + annotation.id.to_s + '" ' + hit_by_search + '  class="annotation_marker annotation_' + annotation.id.to_s + '">' + text_to_replace[replace] + '</span>'
      text = text.gsub(replace, element)
    end
    text
  end

  def speaker_with_text(can_access_annotation = false, annotation_search_count = 0, session_video_text_all = nil)
    font_regex = %r{<font.*?>(.+?)<\/font>}
    if @model.speaker.blank?
      reg_ex = speaker_regex
      return if @model.text.blank?
      text = @model.text.gsub(/\r\n|\r|\n/, '<br>')
      text = text.gsub(/>\s+</, '><')
      text = @model.file_transcript.associated_file_content_type == 'application/msword' ? text.gsub(/(<br>)\1/, '<breaktag>') : text.gsub(/(<br>)\1/, '<breaktag>').gsub('<br>', ' ')
      text = text.gsub('<breaktag>', '<br><br>').strip
      text = text.gsub(font_regex, '\1')
      text = text.force_encoding('UTF-8').strip
      text = append_annotation(text, can_access_annotation, 0, annotation_search_count, session_video_text_all)
      text = text.gsub(reg_ex, format('<a class="play-timecode" href="javascript://" data-timecode="%s">\\0</a>', @model.start_time))
    else
      text = @model.text.force_encoding('UTF-8').strip.gsub(font_regex, '\1')
      text = append_annotation(text, can_access_annotation, @model.speaker.strip.length + 2, annotation_search_count, session_video_text_all)
      text = format('<a class="play-timecode" href="javascript://" data-timecode="%s">%s: </a>%s', @model.start_time, @model.speaker.strip, text)
    end

    replacement, text = prep_string_for_markers(text)

    text = add_marker_occurrences(session_video_text_all, text)

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
