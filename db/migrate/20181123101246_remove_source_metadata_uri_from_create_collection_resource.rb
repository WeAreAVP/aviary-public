# RemoveSourceMetadataUriFromCreateCollectionResource
class RemoveSourceMetadataUriFromCreateCollectionResource < ActiveRecord::Migration[5.1]
  def change
    remove_column :collection_resources, :source_metadata_uri, :string
  end
end
