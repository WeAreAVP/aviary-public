# Organization Field Presenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
class OrganizationFieldPresenter < BasePresenter
  def self.part_of_collection(organization, part_of_collections, system_name, collection)
    if system_name.present? && organization.present? && collection.present?
      part_of_collections[system_name] ||= {}
      part_of_collections[system_name][organization.id] ||= {}
      part_of_collections[system_name][organization.id]['collections'] ||= []
      part_of_collections[system_name][organization.id]['organization_name'] = organization.name
      part_of_collections[system_name][organization.id]['organization_id'] = organization.id
      part_of_collections[system_name][organization.id]['collections'] << collection.title
      part_of_collections[system_name][organization.id]['collections'].uniq!
      part_of_collections[system_name][organization.id]['collection_ids'] ||= []
      part_of_collections[system_name][organization.id]['collection_ids'] << collection.id
      part_of_collections[system_name][organization.id]['collection_ids'].uniq!
    end
    part_of_collections
  end
end
