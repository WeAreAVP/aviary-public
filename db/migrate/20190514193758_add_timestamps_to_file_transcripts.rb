class AddTimestampsToFileTranscripts < ActiveRecord::Migration[5.1]
  def change
    add_column :file_transcripts, :timestamps, :text, limit: 4294967295
  end
end
