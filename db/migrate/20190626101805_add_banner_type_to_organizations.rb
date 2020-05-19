class AddBannerTypeToOrganizations < ActiveRecord::Migration[5.1]
  
  def change
    add_column :organizations, :banner_type, :integer
  end
  
  def down
    remove_column :organizations, :banner_type, :integer
  end
end
