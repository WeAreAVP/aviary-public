class SeedOrganizationTable < ActiveRecord::Migration[5.2]
  def change
    Organization.all.map(&:update_file_index_fields)
  end
end
