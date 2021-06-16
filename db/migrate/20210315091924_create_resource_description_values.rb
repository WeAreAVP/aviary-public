class CreateResourceDescriptionValues < ActiveRecord::Migration[5.2]
  def change
    create_table :resource_description_values do |t|
      t.references :collection_resource
      t.json :resource_field_values
      t.timestamps
    end
  end
end
