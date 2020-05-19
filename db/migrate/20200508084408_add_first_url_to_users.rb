class AddFirstUrlToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :first_url, :text
  end
end
