# Migration for file_indexes Table
class CreateFileIndexes < ActiveRecord::Migration[5.1]
  def change
    create_table :file_indexes do |t|
      t.references :collection_resource_file, foreign_key: true, index: { name: 'crf_fi_index' }
      t.references :user, foreign_key: true, index: { name: 'u_fi_index' }
      t.string :title, null: false
      t.string :language
      t.boolean :is_public, default: false
      t.integer :sort_order
      t.attachment :associated_file
      t.timestamps
    end
    add_index :file_indexes, :title
    add_index :file_indexes, :language
  end
end
