# Add additional columns to users Table Migration
class AddColumnsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :username, :string
    add_column :users, :status, :boolean, default: false
    add_column :users, :preferred_language, :string
    add_column :users, :receive_emails, :boolean
    add_column :users, :updated_by_id, :integer
    add_column :users, :created_by_id, :integer
    change_column :users, :username, :string, :null => false
    change_column :users, :receive_emails, :boolean, :null => false, default: false
    add_index :users, :updated_by_id
    add_index :users, :created_by_id
    add_attachment :users, :photo
  end

  def down
    remove_index :users, :created_by_id
    remove_index :users, :updated_by_id
    remove_column :users, :status, :created_by_id, :updated_by_id, :username, :preferred_language, :receive_emails
    remove_attachment :users, :photo
  end
end
