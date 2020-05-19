# Rename Is Public To Access
class RenameIsPublicToAccess < ActiveRecord::Migration[5.1]
  def change
    rename_column :collection_resources, :is_public, :access
    change_column :collection_resources, :access, :integer
  end
end
