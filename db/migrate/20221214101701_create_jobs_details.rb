class CreateJobsDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :jobs_details do |t|
      t.references :organization
      t.attachment :associated_file
      t.string :job_type
      t.integer "status", default: 0
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
