# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AddInterviewDisplayColumnToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :interview_display_column, :json
  end
end
