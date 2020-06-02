class AddDisplayBannerToCollections < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :display_banner, :boolean, default: true, null: false
  end
end
