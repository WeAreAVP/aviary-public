# RemovePreferredCitationFromCreateCollectionResource
class RemovePreferredCitationFromCreateCollectionResource < ActiveRecord::Migration[5.1]
  def change
    remove_column :collection_resources, :preferred_citation, :string
  end
end
