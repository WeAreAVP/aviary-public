class CreateAnnotationSets < ActiveRecord::Migration[5.2]
  def change
    create_table :annotation_sets do |t|
      t.string :title
      t.boolean :is_public, default: false
      t.references :organization
      t.references :collection_resource
      t.references :file_transcript
      t.text :dublin_core, :limit => 4294967295
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end
    add_index :annotation_sets, :created_by_id
    add_index :annotation_sets, :updated_by_id
  end
end
