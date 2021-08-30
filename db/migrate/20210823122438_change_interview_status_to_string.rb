class ChangeInterviewStatusToString < ActiveRecord::Migration[5.2]
  def change
    change_column :interviews, :interview_status, :string
  end
end
