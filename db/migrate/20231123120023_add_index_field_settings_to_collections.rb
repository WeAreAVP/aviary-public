class AddIndexFieldSettingsToCollections < ActiveRecord::Migration[6.1]
  def change
    Collection.all.each do |col|
      col.add_index_fields_to_collection_fields_and_value
    end
  end
end
