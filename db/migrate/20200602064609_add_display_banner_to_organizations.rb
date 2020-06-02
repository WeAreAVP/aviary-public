class AddDisplayBannerToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :display_banner, :boolean, default: true, null: false
  end
end
