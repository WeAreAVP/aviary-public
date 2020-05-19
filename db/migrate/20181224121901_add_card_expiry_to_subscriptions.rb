class AddCardExpiryToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :card_expiry, :string
  end
end
