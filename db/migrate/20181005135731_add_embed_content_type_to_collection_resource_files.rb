class AddEmbedContentTypeToCollectionResourceFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resource_files, :embed_content_type, :string
  end

  def down
    remove_column :collection_resource_files, :embed_content_type
  end
end
