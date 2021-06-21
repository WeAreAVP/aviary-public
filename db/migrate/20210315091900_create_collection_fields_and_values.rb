class CreateCollectionFieldsAndValues < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_fields_and_values do |t|
      t.references :organization
      t.references :collection
      t.json :collection_fields
      t.json :collection_field_values
      t.json :resource_fields
      t.timestamps
    end
  end
end
