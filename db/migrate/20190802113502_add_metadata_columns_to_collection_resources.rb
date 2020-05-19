class AddMetadataColumnsToCollectionResources < ActiveRecord::Migration[5.1]
  def change
    add_column :collection_resources, :add_rss_information, :boolean, default: false
    add_column :collection_resources, :keywords, :string
    add_column :collection_resources, :explicit, :boolean, default: false
    add_column :collection_resources, :episode_type, :string
    add_column :collection_resources, :episode, :string
    add_column :collection_resources, :season, :string
    add_column :collection_resources, :content, :text
    add_column :collection_resources, :include_in_rss_podcast_feed, :boolean, default: false
  end

  def down
    remove_column :collection_resources, :add_rss_information, :boolean, default: false
    remove_column :collection_resources, :keywords, :string
    remove_column :collection_resources, :explicit, :boolean, default: false
    remove_column :collection_resources, :episode_type, :string
    remove_column :collection_resources, :episode, :string
    remove_column :collection_resources, :season, :string
    remove_column :collection_resources, :content, :text
    remove_column :collection_resources, :include_in_rss_podcast_feed, :boolean, default: false
  end
end
