class AlterFileIndexForInterviewIndex < ActiveRecord::Migration[5.2]
  def change
    add_reference :file_indexes, :interview, foreign_key: true, null: true, index: { name: 'crf_fi_interview_index' }
  end
end
