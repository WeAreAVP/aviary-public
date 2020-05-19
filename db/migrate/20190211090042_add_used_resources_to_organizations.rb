class AddUsedResourcesToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :used_resources, :integer
  end
end
