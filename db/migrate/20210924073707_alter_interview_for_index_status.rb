# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AlterInterviewForIndexStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :index_status, :integer, default: -1
  end
end
