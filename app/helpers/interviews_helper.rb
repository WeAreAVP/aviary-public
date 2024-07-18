# Interviews Helper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module InterviewsHelper
  def self.display_field_title_interview(field)
    case field.to_s
    when 'id_is', 'id_ss'
      'ID'
    when 'title_accession_number_ss'
      'Title | Accession Number'
    when 'collection_id_ss'
      'Collection ID'
    when 'series_id_ss'
      'Series ID'
    when 'date_non_preferred_format'
      'Date (non-preferred format)'
    when 'collection_name'
      'Collection Name'
    when 'thesaurus_keywords'
      'Thesaurus (Keywords)'
    when 'thesaurus_subjects'
      'Thesaurus (Subjects)'
    when 'thesaurus_titles'
      'Thesaurus (Titles)'
    when 'miscellaneous_cms_record_id'
      'CMS Record ID'
    when 'miscellaneous_ohms_xml_filename'
      'OHMS XML Filename'
    when 'miscellaneous_use_restrictions'
      'Use Restrictions'
    when 'miscellaneous_use_restrictions_bs'
      'Use Restrictions'
    when 'miscellaneous_sync_url'
      'Alt Sync URL (Legacy Field)'
    when 'miscellaneous_user_notes'
      'User Notes'
    when 'media_url_texts'
      'Media URL'
    when 'ohms_assigned_user_id_is'
      'Assignments'
    else
      field.to_s.sub('_ss', '').sub('_sms', '').sub('_texts', '').sub('_text', '').sub('_is', '').sub('_bs', '').titleize
    end
  end

  def to_hms(time)
    Time.at(time).utc.strftime('%H:%M:%S')
  rescue StandardError => ex
    Rails.logger.error ex.message
    '00:00:00'
  end

  def hms_to_number(hms)
    hms.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }
  rescue StandardError => ex
    Rails.logger.error ex.message
    0
  end

  def export_csv(interview_id)
    interviews = Interviews::Interview.where(id: interview_id)
    csv_rows = []
    key = 0
    csv_rows << ['Sn#', 'OHMS Record Title', 'Interviewee', 'Accession Number', 'Interview Date', 'Collection ID', 'Collection Name', 'Note Content', 'Note Status', 'Export Date']
    interviews.each do |interview|
      interview.interview_notes.each do |note|
        key += 1
        row = []
        row << key
        row << interview.title
        row << interview.interviewee.join(';;')
        row << interview.accession_number
        row << interview.interview_date
        row << interview.collection_id
        row << interview.collection_name
        row << note['note']
        row << (note['status'] ? 'resolved' : 'unresolved')
        row << DateTime.now.strftime('%Y-%m-%d').to_s
        csv_rows << row
      end
    end
    csv_rows
  end

  def ends_with_punctuation?(line)
    line.strip =~ %r{[!"#.$&'*+\-/<=>?@^_`{|}~]\z} ? true : false
  end

  def fix_line_breaks(transcript)
    processed_transcript = ''
    transcript.split("\n").each { |line| processed_transcript += "#{line}#{line.present? && ends_with_punctuation?(line) ? "\n" : ''}" }
    processed_transcript
  end
end
