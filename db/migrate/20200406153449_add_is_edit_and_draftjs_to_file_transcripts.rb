class AddIsEditAndDraftjsToFileTranscripts < ActiveRecord::Migration[5.1]
  def change
    add_column :file_transcripts, :is_edit, :boolean, default: false
    add_column :file_transcripts, :draftjs, :text, limit: 4294967295
  end
end
