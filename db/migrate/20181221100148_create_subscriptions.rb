# CreateSubscriptions
class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.string :stripe_id
      t.integer :plan_id
      t.string :last_four
      t.string :card_type
      t.float :current_price
      t.integer :organization_id
      t.datetime :start_date
      t.datetime :renewal_date
      t.integer :status
      t.timestamps
    end
  end
end
