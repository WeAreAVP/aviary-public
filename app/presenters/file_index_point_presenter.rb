# FileIndexPointPresenter
# presenters/file_index_point_presenter.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileIndexPointPresenter < BasePresenter
  def display_time
    Time.at(@model.start_time.to_f).utc.strftime('%H:%M:%S')
  end

  def partial_transcript
    return if @model.partial_script.blank?
    '<span class="point_title">Partial Transcript: </span>' + @model.partial_script
  end

  def display_subjects
    return if @model.subjects.blank? || @model.subjects.strip.blank?
    concat_subject = ''
    @model.subjects.split(';').each do |subject|
      concat_subject += '<div class="badge badge-secondary mb-5px">' + subject + '</div>'
    end
    '<div><span class="point_title">Subjects: </span>' + concat_subject + '</div>'
  end

  def display_keywords
    return if @model.keywords.blank? || @model.keywords.strip.blank?
    concat_keywords = ''
    @model.keywords.split(';').each do |keyword|
      concat_keywords += '<div class="badge badge-secondary mb-5px">' + keyword + '</div>'
    end
    '<div><span class="point_title">Keywords: </span>' + concat_keywords + '</div>'
  end

  def single_index_point_hanlder(index_time_start, session_video_text_all)
    text = "<div class='row pt-20px index_time index_custom_identifier #{index_time_start}' id='index_timecode_#{id}' data-id='#{id}' data-index_timecode='#{start_time.to_i} '>
    <div class='col-md-2 text-center timecode_section'>
      <a class='play-timecode' href='javascript://' data-timecode='#{start_time}'>#{display_time}</a>
    </div>
    <div class='col-md-10 content_section'>
      <div class='file_index_mark_custom'>
        <a class='play-timecode' href='javascript://' data-timecode='#{start_time}'>#{title}</a>
      </div>
      <div class='pt-10px file_index_mark_custom'>#{synopsis}</div>
      <div class='pt-10px file_index_mark_custom'>#{partial_transcript}</div>
      <span class='file_index_mark_custom'>#{display_subjects}</span>
      <span class='file_index_mark_custom'>#{display_keywords}</span>
      <div class='pt-10px'> #{gps}</div>
      <div class='pt-10px'>#{display_hyperlink}</div>
    </div>
  </div>"
    if session_video_text_all.present?
      session_video_text_all.each do |key_keyword, single_keyword|
        text = text.gsub(/(#{single_keyword})/i, '<span data-markjs="true" class="highlight-marker mark ' + key_keyword + '">' + single_keyword + '</span>')
      end
    end
    text
  end

  def gps
    return if @model.gps_points.nil?
    gps_points = JSON.parse(@model.gps_points)
    anchor = []
    gps_points.each do |point|
      link = "https://maps.google.com/?q=#{point['lat']},#{point['long']}&z=#{point['zoom']}"
      text = point['description'].present? ? point['description'] : 'GPS Location'
      anchor << "<a target=\"_blank\" href=\"#{link}\">#{text}</a>"
    end
    anchor.join(', ')
  end

  def display_hyperlink
    return if @model.hyperlinks.nil?
    anchor = []
    hyperlinks = JSON.parse(@model.hyperlinks)
    hyperlinks.each do |hyperlink|
      unless hyperlink['hyperlink'].blank?
        text = hyperlink['description'].present? ? hyperlink['description'] : 'Find more information about this here.'
        anchor << "<a target=\"_blank\" href=\"#{hyperlink['hyperlink']}\">#{text}</a>"
      end
    end
    anchor.join(', ')
  end
end
