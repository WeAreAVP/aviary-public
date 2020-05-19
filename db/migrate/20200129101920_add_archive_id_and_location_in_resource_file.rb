class AddArchiveIdAndLocationInResourceFile < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :archive_id, :string
    add_column :collection_resource_files, :archive_location, :string
    add_column :collection_resource_files, :archive_date, :datetime
  end
end
