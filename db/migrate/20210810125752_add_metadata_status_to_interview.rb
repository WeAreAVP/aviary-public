class AddMetadataStatusToInterview < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :metadata_status, :integer
  end
end
