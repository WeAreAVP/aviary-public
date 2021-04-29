class AddDescriptionToFileTranscripts < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :description, :text
  end
end
