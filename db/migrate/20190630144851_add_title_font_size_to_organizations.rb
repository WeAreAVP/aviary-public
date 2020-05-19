class AddTitleFontSizeToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :title_font_size, :string
  end
  
  def down
    remove_column :organizations, :title_font_size, :string
  end
end
