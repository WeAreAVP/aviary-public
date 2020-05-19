class AddStatusToCollection < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :status, :integer
  end
end
