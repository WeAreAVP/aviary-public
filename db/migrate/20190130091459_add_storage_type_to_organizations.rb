class AddStorageTypeToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :storage_type, :integer, default: 2 # 0 => Free Storage, 1 => No Storage, 2 => Wasabi Storage 3=> S3 Storage
  end
end
