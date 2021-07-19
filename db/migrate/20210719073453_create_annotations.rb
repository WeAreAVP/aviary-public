class CreateAnnotations < ActiveRecord::Migration[5.2]
  def change
    create_table :annotations do |t|
      t.references :annotation_set
      t.integer :sequence
      t.integer :motivation # assessing, bookmarking, classifying, commenting, describing, editing, highlighting, identifying, linking, moderating, questioning, replying, tagging
      t.integer :body_type # text, image, video, audio
      t.text :body_content, :limit => 4294967295
      t.string :body_format
      t.integer :target_type # text, image, video, audio
      t.integer :target_content # FileTranscript, FileIndex, CollectionResourceFile
      t.bigint :target_content_id # db id for the object
      t.bigint :target_sub_id # db id for the object
      t.text :target_info # json data
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end
    add_index :annotations, :created_by_id
    add_index :annotations, :updated_by_id
  end
end
