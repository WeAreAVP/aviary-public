# Add Is Caption To File Transcripts
class AddIsCaptionToFileTranscripts < ActiveRecord::Migration[5.1]
  def change
    add_column :file_transcripts, :is_caption, :boolean
  end
end
