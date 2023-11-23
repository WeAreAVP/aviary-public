class AddIndexTemplateInCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :index_template, :integer, default: 0
    add_column :collections, :index_default_template, :integer, default: 1
  end
end
