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
  # ExportOhmsInterviewXml Class for exporting the ohms interview xml
  class ExportOhmsInterviewXml
    def export(interview)
      date = interview.interview_date.empty? ? '' :  Date.strptime(interview.interview_date, '%m/%d/%Y').strftime('%Y-%m-%d')
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
            interview.subjects.each do |subject|
              xml.subject subject
            end
            interview.keywords.each do |keyword|
              xml.keyword keyword
            end
            interview.interviewee.each do |interviewee|
              xml.interviewee interviewee
            end
            interview.interviewer.each do |interviewer|
              xml.interviewer interviewer
            end
            interview.format_info.each do |format|
              xml.format format
            end
            xml.file_name interview.media_filename
            xml.sync interview.transcript_sync_data
            xml.sync_alt interview.transcript_sync_data_translation
            xml.transcript_alt_lang interview.language_for_translation
            xml.translate interview.include_language? ? 1 : 0
            xml.media_id interview.try('media_id').present? ? interview.media_id : ''
            xml.media_url interview.media_url
            xml.mediafile {
              xml.host interview.media_host
              xml.avalon_target_domain interview.try('avalon_target_domain').present? ? interview.avalon_target_domain : ''
              xml.host_account_id interview.try('host_account_id').present? ? interview.host_account_id : ''
              xml.host_player_id interview.try('host_player_id').present? ? interview.host_player_id : ''
              xml.host_clip_id interview.try('host_clip_id').present? ? interview.host_clip_id : ''
              xml.clip_format interview.media_format
            }
            xml.kembed interview.try('kembed').present? ? interview.kembed : ''
            xml.language interview.language_info
            xml.user_notes interview.miscellaneous_user_notes
            xml.index ''
            xml.type interview.media_type
            xml.description interview.summary
            xml.rel interview.try('rel').present? ? interview.rel : ''
            xml.transcript 'No transcript.'
            xml.transcript_alt ''
            xml.rights interview.right_statement
            xml.fmt interview.media_format
            xml.usage interview.usage_statement
            xml.userestrict interview.miscellaneous_use_restrictions? ? 1 : 0
            xml.xmllocation interview.miscellaneous_ohms_xml_filename
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
