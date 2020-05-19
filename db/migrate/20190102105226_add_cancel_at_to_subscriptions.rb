class AddCancelAtToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :cancel_at, :datetime
  end
end
