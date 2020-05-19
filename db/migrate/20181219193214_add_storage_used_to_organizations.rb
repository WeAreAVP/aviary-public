# AddStorageUsedToOrganizations
class AddStorageUsedToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :storage_used, :integer, limit: 8
  end

  def down
    remove_column :organizations, :storage_used
  end
end
