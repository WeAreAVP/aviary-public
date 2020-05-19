# AddStorageLastUpdatedToOrganizations
class AddStorageLastUpdatedToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :storage_last_updated, :datetime
  end

  def down
    remove_column :organizations, :storage_last_updated
  end
end
