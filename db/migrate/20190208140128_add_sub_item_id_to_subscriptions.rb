class AddSubItemIdToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :sub_item_id, :string
  end
end
