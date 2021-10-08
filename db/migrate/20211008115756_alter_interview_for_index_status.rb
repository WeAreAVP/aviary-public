class AlterInterviewForIndexStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :index_status, :integer, default: -1
  end
end
