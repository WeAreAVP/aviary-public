class AddTimeCodeIntervalToFileTranscripts < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :transcript_type, :string
    add_column :file_transcripts, :timecode_intervals, :float
    
  end
end
