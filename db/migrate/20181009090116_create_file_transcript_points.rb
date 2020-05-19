# Migration for file_transcript_points Table
class CreateFileTranscriptPoints < ActiveRecord::Migration[5.1]
  def change
    create_table :file_transcript_points do |t|
      t.references :file_transcript, foreign_key: true, index: { name: 'ft_ftp_index' }
      t.string :title
      t.decimal :start_time, precision: 10, scale: 5
      t.decimal :end_time, precision: 10, scale: 5
      t.decimal :duration, precision: 10, scale: 5
      t.string :speaker
      t.text :text, limit: 4294967295
      t.string :writing_direction
      t.timestamps
    end
    add_index :file_transcript_points, :title
  end
end
