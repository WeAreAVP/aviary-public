class AddBillingAddressToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :billing_address, :text
  end
end
