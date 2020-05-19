class AddFaviconToCollections < ActiveRecord::Migration[5.1]
  def change
    add_attachment :collections, :favicon
  end
end
