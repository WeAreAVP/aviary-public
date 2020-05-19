# Create collection_resources Table Migration
class CreateCollectionResources < ActiveRecord::Migration[5.1]
  def change
    create_table :collection_resources do |t|
      t.references :collection, foreign_key: true, index: { name: 'c_cr_index' }
      t.string :title, nullable: false
      t.boolean :is_featured, default: false
      t.boolean :is_public, default: false
      t.boolean :status, default: false
      t.string :preferred_citation
      t.string :source_metadata_uri
      t.string :duration
      t.integer :external_resource_id
      t.timestamps
    end
  end
end
