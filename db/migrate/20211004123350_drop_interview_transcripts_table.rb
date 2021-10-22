class DropInterviewTranscriptsTable < ActiveRecord::Migration[5.2]
  def change
    drop_table(:interview_transcripts, if_exists: true)
  end
end
