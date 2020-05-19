class AddResourceTableSearchColumnDetailToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :resource_table_search_columns, :text
  end
  
  def down
    remove_column :organizations, :resource_table_search_columns
  end
end
