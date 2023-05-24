class AlterFileTranscriptNotes < ActiveRecord::Migration[6.1]
  def change
    add_column :file_transcripts, :point_notes_info, :json
    add_column :file_transcripts, :notes_info, :json
  end
end