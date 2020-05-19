# Create collection_resource_files Table Migration
class CreateCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :collection_resource_files do |t|
      t.references :collection_resource, foreign_key: true, index: { name: 'cr_crf_index' }
      t.integer :sort_order
      t.text :embed_code
      t.integer :embed_type
      t.attachment :resource_file
      t.attachment :thumbnail
    end
  end
end
