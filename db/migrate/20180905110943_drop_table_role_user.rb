class DropTableRoleUser < ActiveRecord::Migration[5.1]
  def change
    drop_table :roles_users
  end
end
