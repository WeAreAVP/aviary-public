class AddPlayerTypeToCollectionResourceFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :collection_resource_files, :player_type, :string, default: :mediaelement
  end
end
