# AddTargetDomainToCollectionResourceFiles
class AddTargetDomainToCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :target_domain, :string
  end

  def down
    remove_column :collection_resource_files, :target_domain
  end
end
