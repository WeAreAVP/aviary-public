class AddResourceFileDisplayColumnToOrganization < ActiveRecord::Migration[5.1]
  def change
  	add_column :organizations, :resource_file_search_column, :text
  	add_column :organizations, :resource_file_display_column, :text
  end
end
