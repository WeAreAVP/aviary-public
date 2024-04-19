# services/aviary/export_ohms_interview_xml.rb
#
# Module Aviary::export_ohms_interview_xml
# The class is written for exporting the ohms interview xml
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ExportOhmsInterviewXml
  class ExportOhmsInterviewXml
    include XMLFileHandler
    include ApplicationHelper

    SEPARATOR = '--point--'.freeze

    def export(interview)
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.ROOT('xmlns' => 'https://www.weareavp.com/nunncenter/ohms',
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'https://www.weareavp.com/nunncenter/ohms/ohms.xsd') {
          xml.record('id' => interview.id, 'dt' => DateTime.now.strftime('%Y-%m-%d')) {
            add_attributes(xml, interview)

            file_transcript = FileTranscript.find_by(interview_id: interview.id)

            formatted = add_sync(xml, interview, file_transcript)
            file_transcript_alt, formatted_alt = add_sync_alt(xml, interview)

            xml.file_name interview.media_filename

            xml.transcript_alt_lang interview.language_for_translation
            xml.translate interview.include_language? ? 1 : 0
            xml.media_id interview.try('media_id').present? ? interview.media_id : ''
            xml.media_url interview.media_url

            add_mediafile(xml, interview)

            xml.kembed interview.embed_code.present? ? interview.embed_code : ''
            xml.language interview.language_info
            xml.user_notes interview.miscellaneous_user_notes

            add_index(xml, interview)

            xml.type interview.media_type
            xml.description interview.summary
            xml.rel interview.try('rel').present? ? interview.rel : ''

            add_transcript(xml, formatted, file_transcript)
            add_transcript_alt(xml, file_transcript_alt, formatted, formatted_alt)

            xml.rights interview.right_statement
            xml.fmt interview.media_format
            xml.usage interview.usage_statement
            xml.userestrict interview.miscellaneous_use_restrictions? ? 1 : 0

            ohms_configuration = OhmsConfiguration.where('organization_id', interview.organization.id).try(:first)
            if ohms_configuration.present?
              xml.xmllocation "#{ohms_configuration.configuration}/render.php?cachefile=" +
                              interview.miscellaneous_ohms_xml_filename.gsub(/\s+/, '_')
            end
            xml.xmlfilename interview.miscellaneous_ohms_xml_filename
            xml.collection_link interview.collection_link
            xml.series_link interview.series_link
          }
        }
      end

      builder
    end

   def add_attributes(xml, interview)
      xml.version 5.4
      xml.date('value' => interview.interview_date, 'format' => 'yyyy-mm-dd')
      xml.date_nonpreferred_format interview.date_non_preferred_format
      xml.cms_record_id interview.miscellaneous_cms_record_id
      xml.title interview.title
      xml.accession interview.accession_number
      xml.duration interview.media_duration
      xml.collection_id interview.collection_id
      xml.collection_name interview.collection_name
      xml.series_id interview.series_id
      xml.series_name interview.series
      xml.repository interview.organization.name
      xml.funding interview.acknowledgment
      xml.repository_url interview.organization.url

      add_subjects_and_keywords(xml, interview)
      add_interviewers_and_interviewees(xml, interview)
      add_format_info(xml, interview)

      xml.file_name interview.media_filename
    end

    def add_subjects_and_keywords(xml, interview)
      interview.subjects.each { |subject| xml.subject subject } if interview.subjects.present?
      interview.keywords.each { |keyword| xml.keyword keyword } if interview.keywords.present?
    end

    def add_interviewers_and_interviewees(xml, interview)
      interview.interviewee.each { |interviewee| xml.interviewee interviewee } if interview.interviewee.present?
      interview.interviewer.each { |interviewer| xml.interviewer interviewer } if interview.interviewer.present?
    end

    def add_format_info(xml, interview)
      interview.format_info.each { |format| xml.format format } if interview.format_info.present?
    end

    def add_sync(xml, interview, file_transcript)
      formatted = sync = ''

      if file_transcript.present?
        sync, formatted = map_to_ohms_format(file_transcript)
      elsif interview.transcript_sync_data.present?
        sync = interview.transcript_sync_data
      end
      xml.sync sync

      formatted
    end

    def map_to_ohms_format(file_transcript)
      file_transcript_points = insert_footnotes(file_transcript).split(SEPARATOR)

      line_number = 0
      formatted = ''
      sync = "#{file_transcript.timecode_intervals.to_f}:"

      file_transcript_points.each do |point|
        next unless point.present?

        info = point.split("\n")
        info.each do |section|
          next unless section.present?

          breakup = section.split(' ')
          new_line = ''
          breakup.each_with_index do |word, k|
            if "#{new_line}#{word}".length > 80 || k == breakup.length - 1
              formatted = "#{formatted}#{new_line.strip}#{k == breakup.length - 1 ? " #{word}" : ''}\n"
              new_line = ''
            end
            new_line = "#{new_line}#{word} "
          end

          formatted = "#{formatted}\n"
          line_number += 1
        end

        formatted = formatted.delete_suffix("\n")
        formatted_info = formatted.split("\n")
        line = formatted_info.length
        column = formatted_info.last.split(' ').length + 1
        sync += "|#{line}(#{column})" if formatted_info.present?
      end

      note_array = JSON.parse(file_transcript.notes_info) if file_transcript.notes_info.present?
      if note_array.present?
        last = note_array.map { |item| '[[note]]' + item + "[[/note]]\n" }.join
        formatted += "\n[[footnotes]]\n#{last}[[/footnotes]]"
      end

      [sync, formatted]
    end

    def insert_footnotes(file_transcript)
      interpolated_text = file_transcript.file_transcript_points.order('start_time asc')
                                         .try(:pluck, :text).try(:join, SEPARATOR).try(:split, "\n")

      file_transcript.point_notes_info.try(:each) do |key, notes|
        line = interpolated_text[key.to_i]
        phrases = []
        next unless line.present?

        notes.split('|').each do |note|
          tag_number, column = note.split('-')
          current = 0

          split_line_by_separator(line).each do |phrase|
            column = column.to_i
            last = current
            current += phrase.length
            index = (column.zero? ? column : (column - 1)) - last

            phrase[index] = insert_footnote(index, tag_number, phrase) if column >= last && column <= current
            phrases.push(phrase)
          end

          interpolated_text[key.to_i] = phrases.join(SEPARATOR)
        end
      end

      interpolated_text.join("\n")
    end

    def split_line_by_separator(line)
      line.split(SEPARATOR) + (line.end_with?(SEPARATOR) ? [''] : [])
    end

    def insert_footnote(index, tag_number, phrase)
      index.zero? ? (tag(tag_number) + phrase[index]) : (phrase[index] + tag(tag_number))
    end

    def tag(tag_number)
      "[[footnote]]#{tag_number}[[/footnote]]"
    end

    def add_sync_alt(xml, interview)
      sync_alt = interview.transcript_sync_data_translation

      file_transcript_alt = FileTranscript.where(interview_id: interview.id)
      formatted_alt = ''
      if file_transcript_alt.length == 2
        file_transcript_last = file_transcript_alt.last
        sync_alt = "#{file_transcript_last.timecode_intervals.to_f}:"
        file_transcript_last.file_transcript_points.each do |point|
          point.text.split("\n").each do |section|
            formatted_alt += "\n" and next unless section.present?

            breakup = section.split(' ')
            new_line = ''
            breakup.each_with_index do |word, k|
              if "#{new_line}#{word}".length > 80 || k == breakup.length - 1
                formatted_alt += "#{new_line.strip}#{k == breakup.length - 1 ? " #{word}" : ''}\n"
                new_line = ''
              end
              new_line += "#{word} "
            end
          end

          formatted_info = formatted_alt.split("\n")
          line = formatted_info.length
          sync_alt += "|#{line}(#{formatted_info.last.split(' ').length})"
        end
      end

      xml.sync_alt sync_alt

      [file_transcript_alt, formatted_alt]
    end

    def add_mediafile(xml, interview)
      xml.mediafile {
        xml.host interview.media_host
        xml.avalon_target_domain interview.avalon_target_domain.present? ? interview.avalon_target_domain : ''
        xml.host_account_id interview.media_host_account_id.present? ? interview.media_host_account_id : ''
        xml.host_player_id interview.media_host_player_id.present? ? interview.media_host_player_id : ''
        xml.host_clip_id interview.media_host_item_id.present? ? interview.media_host_item_id : ''
        xml.clip_format interview.media_format
      }
    end

    def add_index(xml, interview)
      file_index = FileIndex.find_by(interview_id: interview.id,
                                     language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)))
      file_index_alt = FileIndex.find_by(interview_id: interview.id,
                                         language: interview_lang_info(interview.language_for_translation
                                                                                .gsub(/(\w+)/, &:capitalize)))
      xml.index {
        if file_index.present?
          file_index.file_index_points.sort_by { |t| t.start_time.to_f }.each_with_index do |data, _index|
            file_index_point_alt = get_file_index_point_alt(file_index_alt, data)

            add_index_point(xml, data, file_index_point_alt)
          end
        end
      }
    end

    def get_file_index_point_alt(file_index_alt, data)
      return [] unless file_index_alt.present?

      FileIndexPoint.where(file_index_id: file_index_alt.id).where(start_time: data.start_time.to_f)
                    .where.not(id: data.id)
    end

    def add_index_point(xml, data, file_index_point_alt)
      xml.point {
        xml.time data.start_time.to_i
        xml.title data.title
        xml.title_alt(file_index_point_alt.length.positive? ? file_index_point_alt.first.title : '')
        xml.partial_transcript data.partial_script
        xml.partial_transcript_alt(file_index_point_alt.length.positive? ? file_index_point_alt.first.partial_script : '')
        xml.synopsis data.synopsis
        xml.synopsis_alt(file_index_point_alt.length.positive? ? file_index_point_alt.first.synopsis : '')
        xml.keywords data.keywords
        xml.keywords_alt(file_index_point_alt.length.positive? ? file_index_point_alt.first.keywords : '')
        xml.subjects data.subjects
        xml.subjects_alt(file_index_point_alt.length.positive? ? file_index_point_alt.first.subjects : '')

        add_index_point_gps_points(xml, data, file_index_point_alt)
        add_index_point_hyperlinks(xml, data, file_index_point_alt)
      }
    end

    def add_index_point_gps_points(xml, data, file_index_point_alt)
      if JSON.parse(data.gps_points).length.positive?
        JSON.parse(data.gps_points).each_with_index do |gps_points, g_index|
          xml.gpspoints {
            xml.gps "#{gps_points['lat']}, #{gps_points['long']}"
            xml.gps_zoom gps_points['zoom'].to_i
            xml.gps_text gps_points['description']
            xml.gps_text_alt(file_index_point_alt.length.positive? ? JSON.parse(file_index_point_alt.first.gps_points)[g_index]['description'] : '')
          }
        end
      else
        xml.gpspoints {
          xml.gps ''
          xml.gps_zoom 0
          xml.gps_text ''
          xml.gps_text_alt ''
        }
      end
    end

    def add_index_point_hyperlinks(xml, data, file_index_point_alt)
      if JSON.parse(data.hyperlinks).length.positive?
        JSON.parse(data.hyperlinks).each_with_index do |hyperlinks, h_index|
          xml.hyperlinks {
            xml.hyperlink hyperlinks['hyperlink']
            xml.hyperlink_text hyperlinks['description']
            xml.hyperlink_text_alt(file_index_point_alt.length.positive? ? JSON.parse(file_index_point_alt.first.hyperlinks)[h_index]['description'] : '')
          }
        end
      else
        xml.hyperlinks {
          xml.hyperlink ''
          xml.hyperlink_text ''
          xml.hyperlink_text_alt ''
        }
      end
    end

    def add_transcript(xml, formatted, file_transcript)
      xml.transcript formatted and return if formatted.present?

      xml.transcript Aviary::OhmsTranscriptManager.new.read_notes_info(file_transcript)
    end

    def add_transcript_alt(xml, formatted, formatted_alt, file_transcript_alt)
      xml.transcript_alt '' and return unless file_transcript_alt.length == 2

      xml.transcript_alt = if formatted.present?
                             formatted_alt
                           else
                             Aviary::OhmsTranscriptManager.new.read_notes_info(file_transcript_alt.last)
                           end
    end
  end
end
