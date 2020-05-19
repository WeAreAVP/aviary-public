class AddOrganizationIdToAhoyVisits < ActiveRecord::Migration[5.1]
  def change
    add_reference :ahoy_visits, :organization, foreign_key: true
  end
  
  def remove
    remove_reference :ahoy_visits, :organization
  end
  
end
