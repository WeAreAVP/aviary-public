# frozen_string_literal: true
# AddPlaylistResources
class AddPlaylistResources < ActiveRecord::Migration[5.1]
  def change
    create_table :playlist_resources do |t|
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true
      t.references :collection_resource, foreign_key: true
      t.references :playlist, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.integer :sort_order
      t.decimal :duration, precision: 10, scale: 5
      t.integer :playlist_items_count, default: 0

      t.attachment :thumbnail
      t.timestamps
    end
  end
end
