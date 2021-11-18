class AddExternalIdToFileTranscripts < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :external_id, :integer
  end
end
