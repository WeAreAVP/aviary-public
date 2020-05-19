# AddPlaylist
class AddPlaylists < ActiveRecord::Migration[5.1]
  def change
    create_table :playlists do |t|
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :name, null: false
      t.text :description

      t.integer :access, default: 0, null: false
      t.boolean :is_featured, default: false, null: false
      t.attachment :thumbnail
      t.decimal :duration, precision: 10, scale: 5

      t.boolean :is_rss_enabled
      t.boolean :is_audio_only, default: false, null: false

      t.integer :playlist_resources_count, default: 0
      t.integer :playlist_items_count, default: 0

      t.timestamps
    end
  end
end
