# AddPlaylistItems
class AddPlaylistItems < ActiveRecord::Migration[5.1]
  def change
    create_table :playlist_items do |t|
      t.references :playlist, foreign_key: true
      t.references :playlist_resource, foreign_key: true
      t.references :collection_resource, foreign_key: true
      t.references :collection_resource_file, foreign_key: true

      t.integer :sort_order
      t.decimal :start_time, precision: 10, scale: 5
      t.decimal :end_time, precision: 10, scale: 5

      t.timestamps
    end
  end
end
