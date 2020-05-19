class AddTitleFontFamilyToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :title_font_family, :string
  end
  
  def down
    remove_column :organizations, :title_font_family, :string
  end
end
