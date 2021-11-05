class DropInterviewIndexesTable < ActiveRecord::Migration[5.2]
  def up
    drop_table(:interview_indexes, if_exists: true)
  end
end
