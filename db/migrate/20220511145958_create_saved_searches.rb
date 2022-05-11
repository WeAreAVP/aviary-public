class CreateSavedSearches < ActiveRecord::Migration[6.1]
  def change
    create_table :saved_searches do |t|
      t.string :title
      t.text :note
      t.references :organization, null: true, foreign_key: true
      t.text :url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end