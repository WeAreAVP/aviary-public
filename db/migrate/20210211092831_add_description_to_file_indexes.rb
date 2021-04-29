class AddDescriptionToFileIndexes < ActiveRecord::Migration[5.2]
  def change
    add_column :file_indexes, :description, :text
  end
end
