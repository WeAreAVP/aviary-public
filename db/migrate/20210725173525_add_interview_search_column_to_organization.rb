class AddInterviewSearchColumnToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :interview_search_column, :json
  end
end
