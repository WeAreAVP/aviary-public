class ChangeColumnsTypeForFileTranscriptPoints < ActiveRecord::Migration[5.1]
  def change
    change_column :file_transcript_points, :start_time, :decimal, precision: 20, scale: 5
    change_column :file_transcript_points, :end_time, :decimal, precision: 20, scale: 5
    change_column :file_transcript_points, :duration, :decimal, precision: 20, scale: 5
  end
end
