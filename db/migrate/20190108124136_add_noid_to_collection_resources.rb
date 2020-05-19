class AddNoidToCollectionResources < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resources, :noid, :string
  end
end
