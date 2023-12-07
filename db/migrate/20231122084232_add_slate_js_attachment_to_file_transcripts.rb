class AddSlateJsAttachmentToFileTranscripts < ActiveRecord::Migration[6.1]
  def change
    add_attachment :file_transcripts, :saved_slate_js
  end
end
