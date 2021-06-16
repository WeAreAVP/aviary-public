class AddAutoplayFlagToPlaylists < ActiveRecord::Migration[5.2]
  def change
    add_column :playlists, :dont_autoplay_flag, :boolean, default: true
  end
end
