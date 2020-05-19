# CreateFieldManager
class CreateFieldManager < ActiveRecord::Migration[5.1]
  def change
    create_table :field_manager do |t|
      t.string :label, null: false
      t.string :system_name, null: false
      t.boolean :is_vocabulary, default: false
      t.text :vocabulary
      t.integer :column_type, null: false
      t.text :dropdown_options
      t.boolean :default, default: false
      t.string :help_text
      t.string :source_type, null: false
      t.boolean :is_required, default: false
      t.boolean :is_repeatable, default: false
      t.boolean :is_public, default: true
      t.boolean :is_custom, default: true
      t.timestamps
    end
    add_index :field_manager, :system_name
    add_index :field_manager, :source_type
  end
end
