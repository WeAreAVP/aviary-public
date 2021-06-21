class AddFixedColumnToOrganizationFields < ActiveRecord::Migration[5.2]
  def change
    add_column :organization_fields, :fixed_column, :integer
  end
end
