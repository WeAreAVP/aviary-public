# Interviews Helper
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
    when 'miscellaneous_sync_url'
      'Alt Sync URL (Legacy Field)'
    when 'miscellaneous_user_notes'
      'User Notes'
    when 'thesaurus_titles'
      'Thesaurus (Titles)'
    else
      field.to_s.sub('_ss', '').sub('_sms', '').sub('_texts', '').sub('_text', '').sub('_is', '').sub('_bs', '').titleize
    end
  end
end
