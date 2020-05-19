class UpdateGpsFieldsType < ActiveRecord::Migration[5.1]
  def change
    change_column :file_index_points, :hyperlink, :text
    change_column :file_index_points, :gps_latitude, :text
    change_column :file_index_points, :gps_longitude, :text
    change_column :file_index_points, :gps_zoom, :text
  end

  def down
    change_column :file_index_points, :hyperlink, :string
    change_column :file_index_points, :gps_latitude, :decimal, precision: 10, scale: 5
    change_column :file_index_points, :gps_longitude, :decimal, precision: 10, scale: 5
    change_column :file_index_points, :gps_zoom, :integer
  end
end
