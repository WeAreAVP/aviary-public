class AddBannerSliderResourcesToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :banner_slider_resources, :text
  end
  
  def down
    remove_column :organizations, :banner_slider_resources, :text
  end
end
