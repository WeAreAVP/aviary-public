class AlterCollectionSortOrderColumnOnCollectionResourcesTable < ActiveRecord::Migration[6.1]
  def change
    change_column :collection_resources, :collection_sort_order, :string, default: nil
  end
end
