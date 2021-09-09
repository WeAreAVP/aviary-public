class CreateInterviewsTranscripts < ActiveRecord::Migration[5.2]
  def change
    create_table :interview_transcripts do |t|
      t.references :interview
      t.attachment :associated_file
      t.attachment :translation
      t.boolean :no_transcript, default: false
      t.float :timecode_intervals
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
