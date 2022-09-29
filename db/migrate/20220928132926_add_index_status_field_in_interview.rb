class AddIndexStatusFieldInInterview < ActiveRecord::Migration[6.1]
  def change
    add_column :interviews, :index_status, :integer, default: -1
  end
end
