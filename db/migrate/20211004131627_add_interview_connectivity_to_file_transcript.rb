class AddInterviewConnectivityToFileTranscript < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :interview_transcript_type, :string
    add_column :file_transcripts, :interview_has_transcript, :boolean
  end
end
