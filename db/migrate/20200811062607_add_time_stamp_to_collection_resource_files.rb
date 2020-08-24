class AddTimeStampToCollectionResourceFiles < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :collection_resource_files, null: true

    CollectionResourceFile.where(created_at: nil).each do |single_collection_resource_files|
      time_query = single_collection_resource_files.resource_file_updated_at
      time_query = single_collection_resource_files.thumbnail_updated_at if time_query.blank?
      single_collection_resource_files.update(created_at: time_query, updated_at: time_query)
    end

  end
end
