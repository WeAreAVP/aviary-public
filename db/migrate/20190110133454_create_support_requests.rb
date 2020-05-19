class CreateSupportRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :support_requests do |t|
      t.string :name
      t.string :email
      t.string :organization
      t.text :message
      t.integer :request_type
      t.timestamps
    end
  end
end
