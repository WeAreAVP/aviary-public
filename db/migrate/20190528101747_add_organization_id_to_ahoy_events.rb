class AddOrganizationIdToAhoyEvents < ActiveRecord::Migration[5.1]
  def change
    add_reference :ahoy_events, :organization, foreign_key: true
  end
  
  def remove
    remove_reference :ahoy_events, :organization
  end
end
