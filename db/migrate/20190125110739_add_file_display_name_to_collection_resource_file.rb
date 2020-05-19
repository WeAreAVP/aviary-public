class AddFileDisplayNameToCollectionResourceFile < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :file_display_name, :string
  end
end
