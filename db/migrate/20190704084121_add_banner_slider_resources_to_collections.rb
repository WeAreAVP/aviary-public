class AddBannerSliderResourcesToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :banner_slider_resources, :text
  end
  
  def down
    remove_column :collections, :banner_slider_resources, :text
  end
end
