class AddBucketNameToOrganization < ActiveRecord::Migration[5.1]
  def change
  	add_column :organizations, :bucket_name,  :text
  end
end
