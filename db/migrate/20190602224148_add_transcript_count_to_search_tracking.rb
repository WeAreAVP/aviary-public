class AddTranscriptCountToSearchTracking < ActiveRecord::Migration[5.1]
  def change
    add_column :search_trackings, :transcript_count, :integer
  end

  def down
    remove_column :search_trackings, :transcript_count
  end
end
