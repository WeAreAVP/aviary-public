class AddDisablePlayerToCollection < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :disable_player, :boolean, default: false
  end
end
