class CreateFieldSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :field_settings do |t|
      t.integer :customizable_id, null: false
      t.string :customizable_type, limit: 50
      t.text :settings
      t.timestamps
    end
    add_index :field_settings, %i[customizable_id customizable_type]
  end
end
