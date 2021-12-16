class AlterFileIndexPointForParent < ActiveRecord::Migration[5.2]
  def change
    add_column :file_index_points, :parent_id, :integer, default: 0
  end
end
