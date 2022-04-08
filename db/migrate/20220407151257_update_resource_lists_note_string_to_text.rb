class UpdateResourceListsNoteStringToText < ActiveRecord::Migration[6.1]
  def up
    change_column :resource_lists, :note, :text, :limit => 33554432
  end

  def down
    change_column :resource_lists, :note, :text, :limit => 65536
  end
end
