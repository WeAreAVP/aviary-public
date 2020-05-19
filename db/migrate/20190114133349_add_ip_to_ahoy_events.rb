# Add IP To Ahoy Events
class AddIpToAhoyEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :ahoy_events, :ip, :string
  end
  
end
