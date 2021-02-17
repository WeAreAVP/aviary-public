class AddIs3dToCollectionResourceFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :collection_resource_files, :is_3d, :boolean, default: false
  end
end
