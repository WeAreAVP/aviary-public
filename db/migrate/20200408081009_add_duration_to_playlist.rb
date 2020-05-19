class AddDurationToPlaylist < ActiveRecord::Migration[5.1]
  def change
    failed = []
    Playlist.order(id: :desc).all.each do |single_playlist|
      begin
        single_playlist.playlist_items.first.save
        puts single_playlist.id
        puts 'saved'
      rescue StandardError => error
        puts error
        failed << single_playlist.id
      end
    end
    puts failed
  end
end
