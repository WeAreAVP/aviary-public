class CreateResourceLists < ActiveRecord::Migration[6.1]
  def change
    create_table :resource_lists do |t|
      t.integer :user_id
      t.integer :resource_id
      t.string  :note
      t.timestamps
    end
  end
end
