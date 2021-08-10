# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CreateInterviewsTables < ActiveRecord::Migration[5.2]
  def change
    create_table :interviews do |t|
      t.references :organization, foreign_key: true, index: { name: 'org_interview_index' }
      t.string :title, null: false
      t.string :accession_number, null: true
      t.json :interviewee, null: true
      t.json :interviewer, null: true
      t.string :interview_date, null: true
      t.string :date_non_preferred_format, null: true
      t.string :collection_id, null: true
      t.string :collection_name, null: true
      t.string :collection_link, null: true
      t.string :series_id, null: true
      t.string :series, null: true
      t.text :series_link, null: true
      t.string :media_format, null: false
      t.text :summary, null: true
      t.json :keywords, null: true
      t.json :subjects, null: true
      t.integer :thesaurus_keywords, null: false, default: 0
      t.integer :thesaurus_subjects, null: false, default: 0
      t.integer :thesaurus_titles, null: false, default: 0
      t.text :transcript_sync_data, null: true
      t.text :transcript_sync_data_translation, null: true
      t.json :subjects, null: true
      t.integer :media_host, null: true
      t.text :media_url, null: true
      t.string :media_duration, null: true, default: '00:00:00'
      t.string :media_filename, null: true
      t.string :media_type, null: true
      t.json :format_info, null: true
      t.text :right_statement, null: true
      t.text :usage_statement, null: true
      t.text :acknowledgment, null: true
      t.string :language_info, null: true
      t.boolean :include_language, null: true
      t.string :language_for_translation, null: true
      t.string :miscellaneous_cms_record_id, null: true
      t.string :miscellaneous_ohms_xml_filename, null: true
      t.boolean :miscellaneous_use_restrictions, null: true
      t.string :miscellaneous_sync_url, null: true
      t.text :miscellaneous_user_notes, null: true
      t.integer :interview_status, null: true
      t.integer :status, null: true
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps

    end
  end
end
