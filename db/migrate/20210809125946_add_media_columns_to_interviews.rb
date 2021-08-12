# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AddMediaColumnsToInterviews < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :avalon_target_domain, :string
    add_column :interviews, :embed_code, :text
    add_column :interviews, :media_host_account_id, :string
    add_column :interviews, :media_host_player_id, :string
    add_column :interviews, :media_host_item_id, :string

  end
end
