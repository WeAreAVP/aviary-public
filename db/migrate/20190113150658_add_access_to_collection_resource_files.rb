# AddAccessToCollectionResourceFiles
class AddAccessToCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :access, :integer, default: 1
  end
  def remove
    remove_column :collection_resource_files, :access
  end
end
