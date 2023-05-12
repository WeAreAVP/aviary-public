class CreateThesaurusSettings < ActiveRecord::Migration[6.1]
    def change
      create_table :thesaurus_settings do |t|
        t.references :organization, null: true, foreign_key: true
        t.boolean :is_global, default: false
        t.integer :thesaurus_keywords, default: 0
        t.integer :thesaurus_subjects, default: 0
        t.timestamps
      end
    end
  end