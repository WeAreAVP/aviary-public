# Migration for file_index_point Table
class CreateFileIndexPoints < ActiveRecord::Migration[5.1]
  def change
    create_table :file_index_points do |t|
      t.references :file_index, foreign_key: true, index: { name: 'fi_fip_index' }
      t.string :title, null: false
      t.decimal :start_time, precision: 10, scale: 5
      t.decimal :end_time, precision: 10, scale: 5
      t.decimal :duration, precision: 10, scale: 5
      t.text :synopsis
      t.text :partial_script
      t.decimal :gps_latitude, precision: 10, scale: 5
      t.decimal :gps_longitude, precision: 10, scale: 5
      t.integer :gps_zoom
      t.text :gps_description
      t.string :hyperlink
      t.text :hyperlink_description
      t.text :subjects
      t.text :keywords
      t.timestamps
    end
    add_index :file_index_points, :title
  end
end
