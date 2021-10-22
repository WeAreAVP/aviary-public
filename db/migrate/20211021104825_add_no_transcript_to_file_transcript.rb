class AddNoTranscriptToFileTranscript < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :no_transcript, :boolean
  end
end
