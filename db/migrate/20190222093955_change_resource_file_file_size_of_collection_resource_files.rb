class ChangeResourceFileFileSizeOfCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def up
    change_column :collection_resource_files, :resource_file_file_size, :bigint, limit: 8
  end
  def down
    change_column :collection_resource_files, :resource_file_file_size, :integer
  end
end
