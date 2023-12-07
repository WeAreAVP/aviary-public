class AddCollectionSortOrderToCollectionResources < ActiveRecord::Migration[6.1]
  def change
    add_column :collection_resources, :collection_sort_order, :integer, default: nil
  end
end
