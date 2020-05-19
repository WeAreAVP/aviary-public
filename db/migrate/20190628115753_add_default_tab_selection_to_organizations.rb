class AddDefaultTabSelectionToOrganizations < ActiveRecord::Migration[5.1]
    def change
      add_column :organizations, :default_tab_selection, :integer
    end
    
    def down
      remove_column :organizations, :default_tab_selection, :integer
    end
end
