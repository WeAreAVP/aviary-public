# Create organizations Table Migration
class CreateOrganizations < ActiveRecord::Migration[5.1]
  def change
    create_table :organizations do |t|
      t.references :user, foreign_key: true
      t.string :name, null: false
      t.string :url
      t.text :description
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :country
      t.string :zip
      t.boolean :status, default: true, null: false
      t.boolean :display_banner, default: true, null: false
      t.attachment :logo_image
      t.attachment :banner_image
      t.timestamps
    end
    add_index :organizations, :name
    add_index :organizations, :url, unique: true
  end
end
