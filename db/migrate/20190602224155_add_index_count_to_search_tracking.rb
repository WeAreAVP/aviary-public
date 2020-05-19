class AddIndexCountToSearchTracking < ActiveRecord::Migration[5.1]
  def change
    add_column :search_trackings, :index_count, :integer
  end

  def down
    remove_column :search_trackings, :index_count
  end
end
