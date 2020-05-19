# Add Target Id To Ahoy Events
class AddTargetIdToAhoyEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :ahoy_events, :target_id, :integer
  end
  
  def remove
    remove_column :ahoy_events, :target_id
  end
end
