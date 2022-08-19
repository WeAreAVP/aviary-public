# Interviews Helper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module InterviewsHelper
  def self.display_field_title_interview(field)
    case field.to_s
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
end
