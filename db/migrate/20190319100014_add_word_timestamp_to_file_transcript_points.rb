class AddWordTimestampToFileTranscriptPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :file_transcript_points, :word_timestamp, :text, limit: 4294967295
  end
end
