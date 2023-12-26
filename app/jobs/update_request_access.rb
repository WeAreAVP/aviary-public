# app/jobs/update_request_access.rb
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Update the RequestAccess Solr document belonging with the collection resource when its title is updated.
# This is to remove dependency on the collection_resource Solr document for fetching, searching and sorting the collection_resource_title
# since we have a lot of records, creating a virtual join on the collection_resource Solr document causes an error because the query gets too large
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class UpdateRequestAccess < ApplicationJob
  queue_as :default

  def perform(column, value)
    return unless column.present? && value.present?
    if column == :user_id
      Interviews::Interview.where(ohms_assigned_user_id: value).each do |obj|
        user = User.find(obj.ohms_assigned_user_id)
        if user.present?
          obj.update(ohms_assigned_user_name: user.full_name)
          Sunspot.index obj
          Sunspot.commit
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error e.message
  end
end
