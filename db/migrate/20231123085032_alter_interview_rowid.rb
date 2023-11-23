class AlterInterviewRowid < ActiveRecord::Migration[6.1]
  def change
    add_column :interviews, :ohms_row_id, :integer, default: nil
  end
end
