# Create roles Table Migration
class CreateRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :roles do |t|
      t.string :system_name, null: false
      t.string :name, null: false
      t.timestamps
    end
    create_table :roles_users, id: false do |t|
      t.references :role, foreign_key: true
      t.references :user, foreign_key: true
    end
    add_index :roles, :name, unique: true
    add_index :roles_users, %i[role_id user_id]
    add_index :roles_users, %i[user_id role_id]
  end
end
