class AddDescriptionCountToSearchTracking < ActiveRecord::Migration[5.1]
  def change
    add_column :search_trackings, :description_count, :integer
  end
  
  def down
    remove_column :search_trackings, :description_count
  end
end
