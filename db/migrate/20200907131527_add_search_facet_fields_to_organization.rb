class AddSearchFacetFieldsToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations,  :search_facet_fields, :text
  end
end
