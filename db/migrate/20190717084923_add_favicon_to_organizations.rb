class AddFaviconToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_attachment :organizations, :favicon
  end
end
