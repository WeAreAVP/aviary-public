# CreatePlans
class CreatePlans < ActiveRecord::Migration[5.1]
  def change
    create_table :plans do |t|
      t.string :name
      t.string :stripe_id
      t.float :amount
      t.integer :frequency
      t.integer :max_resources
      t.float :max_size_in_tb
      t.text :additional_features
      t.boolean :highlight, default: false
      t.timestamps
    end
  end
end
