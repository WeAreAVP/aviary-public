class AddAudioOnlyFlagToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :is_audio_only, :boolean
  end
end