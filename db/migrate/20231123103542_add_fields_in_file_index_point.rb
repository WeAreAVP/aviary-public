class AddFieldsInFileIndexPoint < ActiveRecord::Migration[6.1]
  def change
    add_column :file_index_points, :publisher, :json
    add_column :file_index_points, :contributor, :json
    add_column :file_index_points, :segment_date, :json
    add_column :file_index_points, :identifier, :json
    add_column :file_index_points, :rights, :json
  end
end
