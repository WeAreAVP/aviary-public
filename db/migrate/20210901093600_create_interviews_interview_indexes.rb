# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CreateInterviewsInterviewIndexes < ActiveRecord::Migration[5.2]
  def change
    create_table :interview_indexes do |t|
      t.references :interview
      t.string :time, null: false, limit: 255
      t.string :segment_title, null: false, limit: 500
      t.integer :index_status, null: true
      t.text :partial_transcript, null: true
      t.text :keywords, null: true
      t.text :subjects, null: true
      t.text :segment_synopsis, null: true
      t.json :gps, null: true
      t.json :hyperlinks, null: true
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
