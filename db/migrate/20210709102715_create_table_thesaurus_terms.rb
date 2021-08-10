# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CreateTableThesaurusTerms < ActiveRecord::Migration[5.2]
  def change
    create_table :thesaurus_terms do |t|
      t.references :thesaurus_information, null: true
      t.text :term
      t.timestamps
    end
    execute "CREATE FULLTEXT INDEX fulltext_term ON thesaurus_terms (term)" unless Rails.env.test?
  end
end
