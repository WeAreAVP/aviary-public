class AddIndexFieldsToCollectionFields < ActiveRecord::Migration[6.1]
  def change
    add_column :collection_fields_and_values, :index_fields, :json
  end
end
