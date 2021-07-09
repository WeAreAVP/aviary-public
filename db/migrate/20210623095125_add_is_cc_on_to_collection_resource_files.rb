class AddIsCcOnToCollectionResourceFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :collection_resource_files, :is_cc_on, :boolean, default: false
  end
end
