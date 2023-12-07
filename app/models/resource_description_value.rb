# ResourceDescriptionValue
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ResourceDescriptionValue < ApplicationRecord
  belongs_to :collection_resource

  after_save :update_collection_resource_collection_sort_order

  def update_collection_resource_collection_sort_order
    # Updating collection_sort_order without triggering callbacks
    collection_resource.update_column(
      :collection_sort_order, resource_field_values['collection_sort_order']['values'][0]['value'].to_i
    )
  rescue StandardError
    # There is a very high likelyhood collection_sort_order does not exist therefore this rescue
    Rails.logger.error 'collection_sort_order does not exist in resource_description_value'
  end
end
