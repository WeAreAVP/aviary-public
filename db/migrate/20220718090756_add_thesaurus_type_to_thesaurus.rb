class AddThesaurusTypeToThesaurus < ActiveRecord::Migration[6.1]
    def change
      add_column :thesaurus, :thesaurus_type, :string, default: "aviary"
    end
  end