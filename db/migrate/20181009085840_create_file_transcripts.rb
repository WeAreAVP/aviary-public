# Migration for file_transcripts Table
class CreateFileTranscripts < ActiveRecord::Migration[5.1]
  def change
    create_table :file_transcripts do |t|
      t.references :collection_resource_file, foreign_key: true, index: { name: 'crf_ft_index' }
      t.references :user, foreign_key: true, index: { name: 'u_ft_index' }
      t.string :title, null: false
      t.string :language
      t.boolean :is_public, default: false
      t.integer :sort_order
      t.attachment :associated_file
      t.timestamps
    end
    add_index :file_transcripts, :title
    add_index :file_transcripts, :language

  end
end
