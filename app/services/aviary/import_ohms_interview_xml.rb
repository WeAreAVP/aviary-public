# services/aviary/import_ohms_interview_xml.rb
#
# Module Aviary::import_ohms_interview_xml
# The class is written for importing the ohms interview xml
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ImportOhmsInterviewXml
  class ImportOhmsInterviewXml
    include XMLFileHandler
    include ApplicationHelper
    def import(file, organization, user, status)
      doc = Nokogiri::XML(File.read(file.path))

      error_messages = xml_validation(doc)
      if error_messages.any?
        return 'Invalid File, please select a valid OHMS XML file.'
      end
      xml_hash = Hash.from_xml(doc.to_s)
      xml_data = xml_hash['ROOT']['record']

      interview = Interviews::Interview.find_by(ohms_row_id: xml_data['id'].to_i)
      interview = Interviews::Interview.new if interview.nil?
      interview.ohms_row_id = xml_data['id'].to_i
      interview.organization_id = organization.id
      interview.title = xml_data['title'].present? ? xml_data['title'] : ''
      interview.accession_number = xml_data['accession'].present? ? xml_data['accession'] : ''
      interview.interviewee = xml_data['interviewee'].present? ? xml_data['interviewee'] : []
      interview.interviewee = [interview.interviewee] if interview.interviewee.is_a?(String)
      interview.interviewer = xml_data['interviewer'].present? ? xml_data['interviewer'] : []
      interview.interviewer = [interview.interviewer] if interview.interviewer.is_a?(String)
      interview.interview_date = xml_data['date']['value']
      interview.date_non_preferred_format = xml_data['date_nonpreferred_format'].present? ? xml_data['date_nonpreferred_format'] : ''
      interview.collection_id = xml_data['collection_id'].present? ? xml_data['collection_id'] : ''
      interview.collection_name = xml_data['collection_name'].present? ? xml_data['collection_name'] : ''
      interview.collection_link = xml_data['collection_link'].present? ? xml_data['collection_link'] : ''
      interview.series_id = xml_data['series_id'].present? ? xml_data['series_id'] : ''
      interview.series = xml_data['series_name'].present? ? xml_data['series_name'] : ''
      interview.series_link = xml_data['series_link'].present? ? xml_data['series_link'] : ''
      interview.media_format = xml_data['fmt'].present? ? xml_data['fmt'] : ''
      interview.summary = xml_data['description'].present? ? xml_data['description'] : ''
      interview.keywords = xml_data['keyword'].present? ? xml_data['keyword'] : []
      interview.keywords = [interview.keywords] if interview.keywords.is_a?(String)
      interview.subjects = xml_data['subject'].present? ? xml_data['subject'] : []
      interview.subjects = [interview.subjects] if interview.subjects.is_a?(String)
      interview.transcript_sync_data = xml_data['sync'].present? ? xml_data['sync'] : ''
      interview.transcript_sync_data_translation = xml_data['sync_alt'].present? ? xml_data['sync_alt'] : ''
      interview.media_host = xml_data['mediafile']['host'].present? ? xml_data['mediafile']['host'] : ''
      interview.media_url = xml_data['media_url'].present? ? xml_data['media_url'] : ''
      interview.media_duration = xml_data['duration'].present? ? xml_data['duration'] : ''
      interview.media_filename = xml_data['file_name'].present? ? xml_data['file_name'] : ''
      interview.media_type = xml_data['type'].present? ? xml_data['type'] : ''
      interview.format_info = xml_data['format'].present? ? xml_data['format'] : []
      interview.format_info = [interview.format_info] if interview.format_info.is_a?(String)
      interview.right_statement = xml_data['rights'].present? ? xml_data['rights'] : ''
      interview.usage_statement = xml_data['usage'].present? ? xml_data['usage'] : ''
      interview.acknowledgment = xml_data['funding'].present? ? xml_data['funding'] : ''
      interview.language_info = xml_data['language'].present? ? xml_data['language'] : ''
      interview.include_language = xml_data['translate'].present? ? xml_data['translate'] : 0
      interview.language_for_translation = xml_data['transcript_alt_lang'].present? ? xml_data['transcript_alt_lang'] : 'Undefined'
      interview.miscellaneous_cms_record_id = xml_data['cms_record_id'].present? ? xml_data['cms_record_id'] : ''
      interview.miscellaneous_ohms_xml_filename = xml_data['xmlfilename'].present? ? xml_data['xmlfilename'] : ''
      interview.miscellaneous_use_restrictions = xml_data['userestrict'].present? ? xml_data['userestrict'] : 0
      interview.miscellaneous_user_notes = xml_data['user_notes'].present? ? xml_data['user_notes'] : ''
      interview.created_by_id = user.id
      interview.updated_by_id = user.id
      interview.metadata_status = status
      interview.index_status = status
      interview.avalon_target_domain = xml_data['mediafile']['avalon_target_domain'].present? ? xml_data['mediafile']['avalon_target_domain'] : ''
      interview.media_host_account_id = xml_data['mediafile']['host_account_id'].present? ? xml_data['mediafile']['host_account_id'] : ''
      interview.media_host_player_id = xml_data['mediafile']['host_player_id'].present? ? xml_data['mediafile']['host_player_id'] : ''
      interview.media_host_item_id = xml_data['mediafile']['host_clip_id'].present? ? xml_data['mediafile']['host_clip_id'] : ''
      interview.embed_code = xml_data['kembed'].present? ? xml_data['kembed'] : ''
      if interview.valid?
        interview.save
        process_transcript(file, user, interview, xml_data)
        unless xml_data['index'].nil?
          set_points(xml_data, interview, user)
        end
        true
      else
        interview.errors.messages.first
      end
    end

    def process_transcript(file, user, interview, xml_data)
      return unless file.present?
      file_transcript = { title: file.original_filename,
                          is_public: true,
                          language: 'en',
                          associated_file: file,
                          sort_order: interview.file_transcripts.length + 1,
                          user: user,
                          interview_transcript_type: 'main',
                          timecode_intervals: xml_data['sync'].present? ? xml_data['sync'].split(':')[0] : '1',
                          interview_id: interview.id }
      return if interview.nil?
      transcript = interview.file_transcripts.build(file_transcript)
      return unless transcript.valid?
      transcript.save
      ohms_transcript_manager = Aviary::OhmsTranscriptManager.new
      ohms_transcript_manager.from_resource_file = false
      result = ohms_transcript_manager.process(transcript, '', true)
      transcript.destroy if result.present? && result.failure?
    end

    def set_points(xml_data, interview, user)
      return unless xml_data['index']['point'].present?
      file_index = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)))
      file_index = FileIndex.new({ interview_id: interview.id, language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)) }) if file_index.nil?
      file_index.title = interview.title
      file_index.user_id = user.id
      file_index.save(validate: false)
      FileIndexPoint.where(file_index_id: file_index.id).destroy_all
      if interview.include_language
        file_index_alt = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
        file_index_alt = FileIndex.new({ interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)) }) if file_index_alt.nil?
        file_index_alt.title = interview.title
        file_index_alt.user_id = user.id
        file_index_alt.save(validate: false)
        FileIndexPoint.where(file_index_id: file_index_alt.id).destroy_all
      end
      unless xml_data['index']['point'].is_a?(Array)
        xml_data['index']['point'] = [xml_data['index']['point']]
      end
      xml_data['index']['point'].each do |point|
        file_index_point = FileIndexPoint.new
        file_index_point.file_index_id = file_index.id
        file_index_point.title = point['title']
        file_index_point.start_time = point['time'].to_f
        file_index_point.partial_script = (point['partial_transcript'].nil? ? '' : point['partial_transcript'])
        file_index_point.synopsis = (point['synopsis'].nil? ? '' : point['synopsis'])
        file_index_point.keywords = (point['keywords'].nil? ? '' : point['keywords'])
        file_index_point.subjects = (point['subjects'].nil? ? '' : point['subjects'])
        lat = []
        long = []
        zoom = []
        gps_text = []
        gps_text_alt = []
        point['gpspoints'].each do |gpspoints|
          if gpspoints.is_a?(Hash) && gpspoints['gps'].present?
            temp = gpspoints['gps'].split(',')
            if temp.length > 1
              lat << temp[0].strip
              long << temp[1].strip
            else
              long << ''
              long << ''
            end
            zoom << gpspoints['gps_zoom']
            gps_text << gpspoints['gps_text']
            gps_text_alt << gpspoints['gps_text_alt']
          end
        end
        hyperlinks = []
        hyperlink_text = []
        hyperlink_text_alt = []
        point['hyperlinks'].each do |hyperlink|
          if hyperlink.is_a?(Hash) && hyperlink['hyperlink'].present?
            hyperlinks << hyperlink['hyperlink']
            hyperlink_text << hyperlink['hyperlink_text']
            hyperlink_text_alt << hyperlink['hyperlink_text_alt']
          end
        end
        file_index_point.gps_latitude = lat.to_json
        file_index_point.gps_longitude = long.to_json
        file_index_point.gps_zoom = zoom.to_json
        file_index_point.gps_description = gps_text.to_json
        file_index_point.hyperlink = hyperlinks.to_json
        file_index_point.hyperlink_description = hyperlink_text.to_json
        file_index_point = set_end_time(file_index_point)
        file_index_point.save
        if interview.include_language
          file_index_point_alt = FileIndexPoint.new
          file_index_point_alt.file_index_id = file_index_alt.id
          file_index_point_alt.title = point['title_alt']
          file_index_point_alt.start_time = file_index_point.start_time.to_f
          file_index_point_alt.end_time = file_index_point.end_time.to_f
          file_index_point_alt.partial_script = (point['partial_transcript_alt'].nil? ? '' : point['partial_transcript_alt'])
          file_index_point_alt.synopsis = (point['synopsis_alt'].nil? ? '' : point['synopsis_alt'])
          file_index_point_alt.keywords = (point['keywords_alt'].nil? ? '' : point['keywords_alt'])
          file_index_point_alt.subjects = (point['subjects_alt'].nil? ? '' : point['subjects_alt'])
          file_index_point_alt.gps_description = gps_text_alt.to_json
          file_index_point_alt.hyperlink_description = hyperlink_text_alt.to_json
          file_index_point_alt.gps_latitude = lat.to_json
          file_index_point_alt.gps_longitude = long.to_json
          file_index_point_alt.gps_zoom = zoom.to_json
          file_index_point_alt.hyperlink = hyperlinks.to_json
          file_index_point_alt.save
        end
      end
    end
  end
end
