class AddBannerTitleTextToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :banner_title_text, :string
  end
  
  def down
    remove_column :organizations, :banner_title_text, :string
  end
end
