class AddTranscriptDisplaySearchColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :transcript_display_column, :text
    add_column :organizations, :transcript_search_column, :text
  end
end
