class AddPointInfoToFileTranscriptPoints < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcript_points, :point_info, :string
  end
end
