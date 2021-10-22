class FileTranscriptForInterviewTranscript < ActiveRecord::Migration[5.2]
  def change
    add_reference :file_transcripts, :interview, foreign_key: true, null: true, index: { name: 'crf_fi_interview_transcript' }
  end
end
