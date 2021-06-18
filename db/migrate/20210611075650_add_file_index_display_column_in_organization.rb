class AddFileIndexDisplayColumnInOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :file_index_display_column, :text
    add_column :organizations, :file_index_search_column, :text
  end
end
