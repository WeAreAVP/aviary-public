# CreatePublicAccessUrl
class CreatePublicAccessUrl < ActiveRecord::Migration[5.2]
  def change
    create_table :public_access_urls do |t|
      t.references :collection_resource, foreign_key: true
      t.text :url, null: false
      t.string :access_type, null: false
      t.string :duration, null: true
      t.json :information, null: true
      t.boolean :status, default: true
      t.timestamps
    end
  end
end