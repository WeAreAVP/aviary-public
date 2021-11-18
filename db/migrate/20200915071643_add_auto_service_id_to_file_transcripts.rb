# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AddAutoServiceIdToFileTranscripts < ActiveRecord::Migration[5.2]
  def change
    add_column :file_transcripts, :auto_service_id, :string
  end
end
