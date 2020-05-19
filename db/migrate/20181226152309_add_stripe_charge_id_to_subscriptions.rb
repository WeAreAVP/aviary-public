# AddStripeChargeIdToSubscriptions
class AddStripeChargeIdToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :stripe_charge_id, :string
  end
end
