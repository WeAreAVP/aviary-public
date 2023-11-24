class AddIndexTemplateInFileIndex < ActiveRecord::Migration[6.1]
  def change
    add_column :file_indexes, :index_template, :integer, default: 0
    add_column :file_indexes, :index_default_template, :integer, default: 1
  end
end
