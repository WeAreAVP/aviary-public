class AddIndexTemplateInOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :index_template, :integer, default: 0
  end
end
