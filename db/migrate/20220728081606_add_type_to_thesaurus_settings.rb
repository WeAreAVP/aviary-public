class AddTypeToThesaurusSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :thesaurus_settings, :thesaurus_type, :string, default: "index"
  end
end
