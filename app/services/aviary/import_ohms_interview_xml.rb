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
      def import(file, organization, user)
        doc = Nokogiri::XML(File.read(file.path))
        error_messages = xml_validation(doc)
        if error_messages.any?
          return 'Invalid File, please select a valid OHMS XML file.'
        end
        xml_hash = Hash.from_xml(doc.to_s)
        xml_data = xml_hash['ROOT']['record']
        interview = Interviews::Interview.new
        interview.organization_id = organization.id
        interview.title = xml_data['title'].present? ? xml_data['title'] : ''
        interview.accession_number = xml_data['accession'].present? ? xml_data['accession'] : ''
        interview.interviewee = xml_data['interviewee'].present? ? xml_data['interviewee'] : []
        interview.interviewee = [interview.interviewee] if interview.interviewee.is_a?(String)
        interview.interviewer = xml_data['interviewer'].present? ? xml_data['interviewer'] : []
        interview.interviewer = [interview.interviewer] if interview.interviewer.is_a?(String)
        interview.interview_date = if xml_data['date']['value'].present? && !xml_data['date']['value'].empty?
                                     Date.strptime(xml_data['date']['value']).strftime('%m/%d/%Y')
                                   else
                                     ''
                                   end
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
        interview.language_for_translation = xml_data['transcript_alt_lang'].present? ? xml_data['transcript_alt_lang'] : ''
        interview.miscellaneous_cms_record_id = xml_data['cms_record_id'].present? ? xml_data['cms_record_id'] : ''
        interview.miscellaneous_ohms_xml_filename = xml_data['xmllocation'].present? ? xml_data['xmllocation'] : ''
        interview.miscellaneous_use_restrictions = xml_data['userestrict'].present? ? xml_data['userestrict'] : 0
        interview.miscellaneous_user_notes = xml_data['user_notes'].present? ? xml_data['user_notes'] : ''
        interview.created_by_id = user.id
        interview.updated_by_id = user.id
        interview.metadata_status = -1
        interview.avalon_target_domain = xml_data['avalon_target_domain'].present? ? xml_data['avalon_target_domain'] : ''
        if interview.valid?
          interview.save
          true
        else
          interview.errors.messages.first
        end
      end
    end
end