class AddCollectionCardImageToCollections < ActiveRecord::Migration[5.2]
  def change
    add_attachment :collections, :card_image
  end
end
