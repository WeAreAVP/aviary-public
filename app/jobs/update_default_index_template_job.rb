# app/jobs/update_default_index_template_job.rb
#
# The job will run in the background to update default index template in collections and file indexes
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class UpdateDefaultIndexTemplateJob < ApplicationJob
  queue_as :default

  def perform(organization, type, index_template, index_default_template = '', collection_id = 0)
    if type == 'organization'
      organization.collections.where(index_default_template: 1).update_all(index_template: index_template.to_i)
      FileIndex.includes(collection_resource_file: { collection_resource: { collection: :organization } }).where(collections: { index_default_template: 1 }).where(organizations: { id: organization.id }).where(index_default_template: 1).update_all(index_template: index_template.to_i)
    elsif type == 'collection'
      if index_default_template.nil?
        FileIndex.includes(collection_resource_file: { collection_resource: :collection }).where(collections: { id: collection_id }).where(index_default_template: 1).update_all(index_template: index_template.to_i)
      elsif index_default_template.present? && index_default_template.to_i.positive?
        FileIndex.includes(collection_resource_file: { collection_resource: :collection }).where(collections: { id: collection_id }).where(index_default_template: 1).update_all(index_template: organization.index_template.to_i)
      end
    end
  end
end
