class RemoveColumnsFromOrganizations < ActiveRecord::Migration[5.2]
  def up
    remove_column :organizations, :display_banner
    remove_column :organizations, :banner_title_type

    remove_attachment :organizations, :banner_title_image
  end

  def down
    add_column :organizations, :banner_title_type, :integer
    add_column :organizations, :display_banner, :boolean, default: true, null: false
    add_attachment :organizations, :banner_title_image
  end
end
