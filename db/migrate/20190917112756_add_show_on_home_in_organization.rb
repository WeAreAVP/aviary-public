class AddShowOnHomeInOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :hide_on_home, :boolean, default: false
  end

  def down
    remove_column :organizations, :hide_on_home, :boolean, default: false
  end
end
