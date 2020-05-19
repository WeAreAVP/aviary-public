# AddUserTypeToAhoyVisits
class AddUserTypeToAhoyVisits < ActiveRecord::Migration[5.1]
  def change
    add_column :ahoy_visits, :user_type, :text
  end
  
  def down
    remove_column :ahoy_visits, :user_type, :text
  end
end