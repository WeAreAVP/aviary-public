class CreateOrganizationFields < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_fields do |t|
      t.references :organization
      t.json :collection_fields
      t.json :resource_fields
      t.timestamps
    end
  end
end
