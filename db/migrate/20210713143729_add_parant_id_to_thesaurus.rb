class AddParantIdToThesaurus < ActiveRecord::Migration[5.2]
  def change
    add_column :thesaurus, :parent_id, :integer
  end
end
