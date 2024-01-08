class ChangeParentIdColumnInFileIndexPointsTable < ActiveRecord::Migration[6.1]
  def change
    FileIndexPoint.where(parent_id: nil).update_all(parent_id: 0)

    change_column :file_index_points, :parent_id, :integer, :null => false, default: 0
  end
end
