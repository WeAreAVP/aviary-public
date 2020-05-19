class AddLockedByToFileTranscripts < ActiveRecord::Migration[5.1]
  def change
    add_column :file_transcripts, :locked_by, :bigint, null: true
  end
end
