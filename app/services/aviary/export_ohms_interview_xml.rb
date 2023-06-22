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
    def export(interview)
      date = interview.interview_date.empty? ? '' : Date.strptime(interview.interview_date, '%m/%d/%Y').strftime('%Y-%m-%d')
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.ROOT('xmlns' => 'https://www.weareavp.com/nunncenter/ohms', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'https://www.weareavp.com/nunncenter/ohms/ohms.xsd') {
          xml.record('id' => interview.id, 'dt' => DateTime.now.strftime('%Y-%m-%d')) {
            xml.version 5.4
            xml.date('value' => date, 'format' => 'yyyy-mm-dd')
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

            if interview.subjects.present?
              interview.subjects.each do |subject|
                xml.subject subject
              end
            end

            if interview.keywords.present?
              interview.keywords.each do |keyword|
                xml.keyword keyword
              end
            end

            if interview.interviewee.present?
              interview.interviewee.each do |interviewee|
                xml.interviewee interviewee
              end
            end

            if interview.interviewer.present?
              interview.interviewer.each do |interviewer|
                xml.interviewer interviewer
              end
            end

            if interview.format_info.present?
              interview.format_info.each do |format|
                xml.format format
              end
            end

            xml.file_name interview.media_filename
            file_transcript = FileTranscript.find_by(interview_id: interview.id)
            formatted = ''
            if interview.transcript_sync_data
              xml.sync interview.transcript_sync_data
            elsif file_transcript.present?
              file_transcript_points = FileTranscriptPoint.where(file_transcript_id: file_transcript)
              sync = "#{file_transcript.timecode_intervals.to_i}:"

              file_transcript_points.each do |point|
                info = point.text.split("\n")
                info.each do |section|
                  if section.present?
                    breakup = section.split(' ')
                    new_line = ''
                    breakup.each_with_index do |word, k|
                      if "#{new_line}#{word}".length > 80 || k == breakup.length - 1
                        formatted = "#{formatted}#{new_line.strip}#{k == breakup.length - 1 ? " #{word}" : ''}\r\n"
                        new_line = ''
                      end
                      new_line = "#{new_line}#{word} "
                    end
                    formatted = "#{formatted}\r\n"
                  end
                end
                formatted_info = formatted.split("\r\n")
                line = formatted_info.length
                sync += "|#{line}(#{formatted_info.last.split(' ').length})"
              end
              xml.sync sync
            else
              xml.sync ''
            end
            xml.sync_alt interview.transcript_sync_data_translation
            xml.transcript_alt_lang interview.language_for_translation
            xml.translate interview.include_language? ? 1 : 0
            xml.media_id interview.try('media_id').present? ? interview.media_id : ''
            xml.media_url interview.media_url
            xml.mediafile {
              xml.host interview.media_host
              xml.avalon_target_domain interview.avalon_target_domain.present? ? interview.avalon_target_domain : ''
              xml.host_account_id interview.media_host_account_id.present? ? interview.media_host_account_id : ''
              xml.host_player_id interview.media_host_player_id.present? ? interview.media_host_player_id : ''
              xml.host_clip_id interview.media_host_item_id.present? ? interview.media_host_item_id : ''
              xml.clip_format interview.media_format
            }

            xml.kembed interview.embed_code.present? ? interview.embed_code : ''
            xml.language interview.language_info
            xml.user_notes interview.miscellaneous_user_notes
            file_index = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)))
            file_index_alt = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
            xml.index {
              if file_index.present?
                file_index.file_index_points.sort_by { |t| t.start_time.to_f }.each_with_index do |data, _index|
                  file_index_point_alt = []
                  file_index_point_alt = FileIndexPoint.where(file_index_id: file_index_alt.id).where(start_time: data.start_time.to_f).where.not(id: data.id) if file_index_alt.present?
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
                  }
                end
              end
            }
            xml.type interview.media_type
            xml.description interview.summary
            xml.rel interview.try('rel').present? ? interview.rel : ''
            file_transcript = FileTranscript.find_by(interview_id: interview.id)
            transcript_manager = Aviary::OhmsTranscriptManager.new

            if formatted.present?
              xml.transcript formatted
            else
              xml.transcript transcript_manager.read_notes_info(file_transcript)
            end
            xml.transcript_alt ''
            xml.rights interview.right_statement
            xml.fmt interview.media_format
            xml.usage interview.usage_statement
            xml.userestrict interview.miscellaneous_use_restrictions? ? 1 : 0
            ohms_configuration = OhmsConfiguration.where('organization_id', interview.organization.id).try(:first)
            xml.xmllocation "#{ohms_configuration.configuration}/render.php?cachefile=#{interview.miscellaneous_ohms_xml_filename.gsub(/\s+/, '_')}" if ohms_configuration.present?
            xml.xmlfilename interview.miscellaneous_ohms_xml_filename
            xml.collection_link interview.collection_link
            xml.series_link interview.series_link
          }
        }
      end
      builder
    end
  end
end
