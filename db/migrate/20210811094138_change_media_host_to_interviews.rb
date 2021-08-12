class ChangeMediaHostToInterviews < ActiveRecord::Migration[5.2]
  def change
    change_column :interviews, :media_host, :string
  end
end
