class CreateFieldValues < ActiveRecord::Migration[5.1]
  def change
    create_table :field_values do |t|
      t.integer :customizable_id, null: false
      t.string :customizable_type, limit: 50
      t.text :values, :limit => 4294967295
      t.timestamps
    end
    add_index :field_values, %i[customizable_id customizable_type]
  end
end
