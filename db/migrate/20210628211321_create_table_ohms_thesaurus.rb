class CreateTableOhmsThesaurus < ActiveRecord::Migration[5.2]
  def change
    create_table :ohms_thesaurus do |t|
      t.references :organization
      t.string :title
      t.text :description
      t.integer :status
      t.json :thesaurus_terms
      t.integer :number_of_terms
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
