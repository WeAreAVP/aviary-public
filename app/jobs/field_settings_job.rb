# app/jobs/field_settings_job.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FieldSettingsJob < ApplicationJob
  queue_as :default

  def perform(collection, fields, type)
    collection.update_field_settings(fields, type)
  rescue StandardError => e
    Rails.logger.error e.message
  end
end
