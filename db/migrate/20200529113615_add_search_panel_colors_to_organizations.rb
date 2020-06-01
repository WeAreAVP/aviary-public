class AddSearchPanelColorsToOrganizations < ActiveRecord::Migration[5.2]
  def up
    add_column :organizations, :search_panel_font_color, :string
    add_column :organizations, :search_panel_bg_color, :string
  end

  def down
    remove_column :organizations, :search_panel_font_color
    remove_column :organizations, :search_panel_bg_color
  end
end
