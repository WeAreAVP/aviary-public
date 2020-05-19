class AddBannerTypeToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :banner_type, :integer
  end
  
  def down
    remove_column :collections, :banner_type, :integer
  end
end
