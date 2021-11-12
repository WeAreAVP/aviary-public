class AddExternalIdToCollectionResourceFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :collection_resource_files, :external_id, :integer
  end
end
