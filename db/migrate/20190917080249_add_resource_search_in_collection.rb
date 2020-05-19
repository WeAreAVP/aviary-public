class AddResourceSearchInCollection < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :search_resource_placeholder, :string, default: 'Search this Resource'
    add_column :collections, :enable_resource_search, :boolean, default: true
  end

  def down
    remove_column :collections, :search_resource_placeholder, :string, default: 'Search this Resource'
    remove_column :collections, :enable_resource_search, :boolean, default: true
  end
end
