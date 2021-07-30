class AddInterviewDisplayColumnToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :interview_display_column, :json
  end
end
