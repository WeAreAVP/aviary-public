class AddIsDownloadableInMedia < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :is_downloadable, :boolean, default: false
    add_column :collection_resource_files, :download_enabled_for, :string, default: nil
    add_column :collection_resource_files, :downloadable_duration, :string, default: nil
    add_column :collection_resource_files, :total_time_enabled, :datetime, default: nil
  end
end
