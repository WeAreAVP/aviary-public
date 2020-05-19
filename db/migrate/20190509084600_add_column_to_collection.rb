class AddColumnToCollection < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :subject, :text
    add_column :collections, :from_name, :string
  end
end
