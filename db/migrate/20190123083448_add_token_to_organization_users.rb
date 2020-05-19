class AddTokenToOrganizationUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :organization_users, :token, :string
  end
end
