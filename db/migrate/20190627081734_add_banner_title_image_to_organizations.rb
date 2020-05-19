class AddBannerTitleImageToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_attachment :organizations, :banner_title_image
  end

  def down
    remove_attachment :organizations, :banner_title_image
  end
end
