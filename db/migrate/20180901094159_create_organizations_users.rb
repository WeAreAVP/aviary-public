# Create organization_users Table Migration
class CreateOrganizationsUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :organization_users do |t|
      t.references :organization, foreign_key: true
      t.references :user, foreign_key: true
      t.references :role, foreign_key: true
      t.boolean :status, default: true
    end
    add_index :organization_users, %i[organization_id user_id], unique: true
  end
end
