class CreateTableThesaurus < ActiveRecord::Migration[5.2]
  def change
    create_table :thesaurus do |t|
      t.references :organization
      t.string :title
      t.text :description
      t.integer :status
      t.json :thesaurus_terms
      t.integer :number_of_terms
      t.integer :type_of_thesaurus
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
