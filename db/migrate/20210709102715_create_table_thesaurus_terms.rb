class CreateTableThesaurusTerms < ActiveRecord::Migration[5.2]
  def change
    create_table :thesaurus_terms do |t|
      t.references :thesaurus_information, null: true
      t.text :term
      t.timestamps
    end
    execute "CREATE FULLTEXT INDEX fulltext_term ON thesaurus_terms (term)"
  end
end
