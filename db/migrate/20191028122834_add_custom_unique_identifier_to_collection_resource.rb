class AddCustomUniqueIdentifierToCollectionResource < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resources, :custom_unique_identifier, :string
  end
end
