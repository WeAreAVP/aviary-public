# 
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CreateInterviewsInterviewNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :interview_notes do |t|
      t.references :interview
      t.boolean :status, default: false
      t.text :note, null: false
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end