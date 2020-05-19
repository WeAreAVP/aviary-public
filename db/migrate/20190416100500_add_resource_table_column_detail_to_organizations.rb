# AddResourceTableColumnDetailToOrganizations
class AddResourceTableColumnDetailToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :resource_table_column_detail, :text
  end
  
  def down
    remove_column :organizations, :resource_table_column_detail
  end
end
