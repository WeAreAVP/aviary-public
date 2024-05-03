class ChangeOhmsRowIdToBeStringInInterviews < ActiveRecord::Migration[6.1]
    def change
      change_column :interviews, :ohms_row_id, :string
    end
end