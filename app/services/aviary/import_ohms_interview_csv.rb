# services/aviary/import_ohms_interview_csv.rb
#
# Module Aviary::import_ohms_interview_csv
# The class is written for importing the ohms interview csv
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ImportOhmsInterviewCsv
  class ImportOhmsInterviewCsv
    include XMLFileHandler
    include ApplicationHelper
    def import(file, organization, user, status)
      csv = CSV.new(open(file.path), headers: true, encoding: 'ISO8859-1:utf-8')
      csv_raw = []
      return csv_raw unless csv.present?
      csv.each do |unstriped_row|
        row = {}
        if unstriped_row.present?
          unstriped_row.each do |k, v|
            row[k.to_s.strip] = v.to_s.strip
          end
          csv_raw << row
        end
      end
      return unless csv_raw.length.positive?

      csv_raw.each do |row|
        process(organization, user, status, row)
      end

      true
    rescue StandardError => ex
      ex
    end

    def process(organization, user, status, csv_raw)
      interview = Interviews::Interview.find_by(id: csv_raw['rowid'])
      interview = Interviews::Interview.new if interview.nil?

      interview.organization_id = organization.id
      interview.title = csv_raw['Title'].present? ? csv_raw['Title'] : ''
      interview.accession_number = csv_raw['Accession Number'].present? ? csv_raw['Accession Number'] : ''
      interview.interviewee = csv_raw['Interviewee'].present? ? csv_raw['Interviewee'].split(';') : []
      interview.interviewer = csv_raw['Interviewer'].present? ? csv_raw['Interviewer'].split(';') : []
      interview.interview_date = if csv_raw['Day'].present? && !csv_raw['Day'].empty? &&
                                    Date.valid_date?(csv_raw['Year'].to_i, csv_raw['Month'].to_i, csv_raw['Day'].to_i)

                                   DateTime.new(csv_raw['Year'].to_i, csv_raw['Month'].to_i, csv_raw['Day'].to_i).strftime('%m/%d/%Y')
                                 else
                                   ''
                                 end
      interview.date_non_preferred_format = csv_raw['Date (non-preferred format)'].present? ? csv_raw['Date (non-preferred format)'] : ''
      interview.collection_id = csv_raw['Collection ID'].present? ? csv_raw['Collection ID'] : ''
      interview.collection_name = csv_raw['Collection'].present? ? csv_raw['Collection'] : ''
      interview.collection_link = csv_raw['Collection Link'].present? ? csv_raw['Collection Link'] : ''
      interview.series_id = csv_raw['Series ID'].present? ? csv_raw['Series ID'] : ''
      interview.series = csv_raw['Series'].present? ? csv_raw['Series'] : ''
      interview.series_link = csv_raw['Series Link'].present? ? csv_raw['Series Link'] : ''
      interview.media_format = csv_raw['Media Format'].present? ? csv_raw['Media Format'] : ''
      interview.summary = csv_raw['Summary'].present? ? csv_raw['Summary'] : ''
      interview.keywords = csv_raw['Keywords'].present? ? csv_raw['Keywords'].split(';') : []
      interview.subjects = csv_raw['Subject'].present? ? csv_raw['Subject'].split(';') : []
      interview.transcript_sync_data = csv_raw['Transcript Sync Data'].present? ? csv_raw['Transcript Sync Data'] : ''
      interview.transcript_sync_data_translation = csv_raw['Transcript Sync Data (Translation)'].present? ? csv_raw['Transcript Sync Data (Translation)'] : ''
      interview.media_host = csv_raw['Media Host'].present? ? csv_raw['Media Host'] : ''
      interview.media_url = csv_raw['Media URL'].present? ? csv_raw['Media URL'] : ''
      interview.media_duration = csv_raw['Duration'].present? ? csv_raw['Duration'] : ''
      interview.media_filename = csv_raw['Media Filename'].present? ? csv_raw['Media Filename'] : ''
      interview.media_type = csv_raw['Type'].present? ? csv_raw['Type'] : ''
      interview.format_info = csv_raw['Format'].present? ? csv_raw['Format'].split(';') : []
      interview.right_statement = csv_raw['Rights'].present? ? csv_raw['Rights'] : ''
      interview.usage_statement = csv_raw['Usage'].present? ? csv_raw['Usage'] : ''
      interview.acknowledgment = csv_raw['Acknowledgement'].present? ? csv_raw['Acknowledgement'] : ''
      interview.language_info = csv_raw['Language'].present? ? csv_raw['Language'] : ''
      interview.include_language = ((csv_raw['Include Translation'].present? && csv_raw['Include Translation'] == 'yes') || csv_raw['Include Translation'].present?)

      interview.language_for_translation = csv_raw['Language for Translation'].present? ? csv_raw['Language for Translation'] : 'Undefined'
      interview.miscellaneous_cms_record_id = csv_raw['CMS Record ID'].present? ? csv_raw['CMS Record ID'] : ''
      interview.miscellaneous_ohms_xml_filename = csv_raw['OHMS XML Filename'].present? ? csv_raw['OHMS XML Filename'] : ''
      interview.miscellaneous_use_restrictions = (csv_raw['Use Restrictions'].present? && csv_raw['Use Restrictions'] == 'yes')
      interview.miscellaneous_user_notes = csv_raw['User Notes'].present? ? csv_raw['User Notes'] : ''
      interview.created_by_id = user.id
      interview.updated_by_id = user.id
      interview.metadata_status = status
      interview.index_status = status
      interview.avalon_target_domain = csv_raw['Avalon Target Domain'].present? ? csv_raw['Avalon Target Domain'] : ''
      interview.media_host_account_id = csv_raw['Media Host Account ID'].present? ? csv_raw['Media Host Account ID'] : ''
      interview.media_host_player_id = csv_raw['Media Host Player ID'].present? ? csv_raw['Media Host Player ID'] : ''
      interview.media_host_item_id = csv_raw['Media Host Item ID'].present? ? csv_raw['Media Host Item ID'] : ''
      interview.embed_code = csv_raw['Embed Code'].present? ? csv_raw['Embed Code'] : ''
      interview.miscellaneous_sync_url = csv_raw['Alt Sync URL'].present? ? csv_raw['Alt Sync URL'] : ''

      if interview.valid?
        interview.save
        process_transcript(csv_raw, user, interview)
        set_points(csv_raw, interview, user)
        true
      else
        interview.errors.messages.first
      end
    end

    def process_transcript(csv_raw, user, interview)
      transcripts = []
      csv_raw.each do |item|
        transcripts << item[1] if item[0].include?('Transcript_')
      end
      main_transcript = Sanitize.fragment(transcripts.join("\n"))
      file = Tempfile.new('content')
      file.path
      file.write(main_transcript)
      return unless transcripts.length.positive?
      file_transcript = { title: csv_raw['Title'],
                          is_public: true,
                          associated_file: file,
                          language: 'en',
                          sort_order: interview.file_transcripts.length + 1,
                          user: user,
                          interview_transcript_type: 'main',
                          timecode_intervals: csv_raw['Transcript Sync Data'].present? ? csv_raw['Transcript Sync Data'].split(':')[0] : '1',
                          interview_id: interview.id }
      return if interview.nil?

      transcript = interview.file_transcripts.build(file_transcript)
      return unless transcript.valid?
      transcript.save
      ohms_transcript_manager = Aviary::OhmsTranscriptManager.new
      ohms_transcript_manager.from_resource_file = false
      result = ohms_transcript_manager.process(transcript, '', true, false, csv_raw)
      transcript.destroy if result.present? && result.failure?
      file.close
      file.unlink
    end

    def set_points(csv_raw, interview, user)
      i = 0
      while csv_raw["Index_#{i}"].present?
        point = csv_raw["Index_#{i}"].split(' --- ')
        if point.length == 16
          file_index = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)))
          file_index = FileIndex.new({ interview_id: interview.id, language: interview_lang_info(interview.language_info.gsub(/(\w+)/, &:capitalize)) }) if file_index.nil?
          file_index.title = interview.title
          file_index.user_id = user.id
          file_index.save(validate: false)
          if interview.include_language
            file_index_alt = FileIndex.find_by(interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)))
            file_index_alt = FileIndex.new({ interview_id: interview.id, language: interview_lang_info(interview.language_for_translation.gsub(/(\w+)/, &:capitalize)) }) if file_index_alt.nil?
            file_index_alt.title = interview.title
            file_index_alt.user_id = user.id
            file_index_alt.save(validate: false)
          end
          file_index_point = FileIndexPoint.new
          file_index_point.file_index_id = file_index.id
          file_index_point.title = point[1]
          file_index_point.start_time = point[0].to_f
          file_index_point.partial_script = point[3]
          file_index_point.synopsis = point[5]
          file_index_point.keywords = point[7]
          file_index_point.subjects = point[8]
          file_index_point = set_end_time(file_index_point)
          file_index_point.save
          if interview.include_language
            file_index_point_alt = FileIndexPoint.new
            file_index_point_alt.file_index_id = file_index_alt.id
            file_index_point_alt.title = point[2]
            file_index_point_alt.start_time = point[0].to_f
            file_index_point_alt.end_time = file_index_point.end_time.to_f
            file_index_point_alt.partial_script = point[4]
            file_index_point_alt.synopsis = point[6]
            file_index_point_alt.keywords = point[7]
            file_index_point_alt.subjects = point[8]
            file_index_point_alt.save
          end
        end

        i += 1
      end
    end
  end
end
