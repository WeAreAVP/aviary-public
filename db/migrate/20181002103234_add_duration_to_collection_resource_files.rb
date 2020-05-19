# Add duration column to collection_resource_files table
class AddDurationToCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :duration, :decimal, precision: 10, scale: 5
  end

  def down
    remove_column :collection_resource_files, :duration
  end
end
