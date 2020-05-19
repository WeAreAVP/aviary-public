class CreateSearchTrackings < ActiveRecord::Migration[5.1]
  def change
    create_table :search_trackings do |t|
      t.string :search_type
      t.integer :result_count
      t.string :search_keyword

      t.timestamps
    end
  end
end
