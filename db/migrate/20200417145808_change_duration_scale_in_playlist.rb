class ChangeDurationScaleInPlaylist < ActiveRecord::Migration[5.1]
  def change
    change_column :playlists, :duration, :double, :precision => 4, :scale => 7
  end
end
