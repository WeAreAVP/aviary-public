# RemoveDurationFromCreateCollectionResource
class RemoveDurationFromCreateCollectionResource < ActiveRecord::Migration[5.1]
  def change
    remove_column :collection_resources, :duration, :string
  end
end
