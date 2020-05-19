class AddBannerTitleTypeToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :banner_title_type, :integer
  end

  def down
    remove_column :organizations, :banner_title_type, :integer
  end
end
