class AddTranscriptStatusToFileTranscripts < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :sync_status, :integer
  end
end
