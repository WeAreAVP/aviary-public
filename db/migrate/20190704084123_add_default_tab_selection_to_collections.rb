class AddDefaultTabSelectionToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :default_tab_selection, :integer
  end
  
  def down
    remove_column :collections, :default_tab_selection, :integer
  end
end
