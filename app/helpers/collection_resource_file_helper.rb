# Detail ArchivesSpaceHelper Helper
# CollectionResourceFileHelper
module CollectionResourceFileHelper
  def display_field(field)
    current_organization.resource_file_display_column.map { |_a, b| b['status'] if b['value'] == field }.compact.first
  end

  def permission_to_access_file?(resource_file)
    (can? :read, resource_file) || resource_file.collection_resource.can_view || resource_file.collection_resource.can_edit || (can? :edit, resource_file.collection_resource.collection.organization)
  rescue StandardError
    false
  end

  def permission_to_access_resource?(collection_resource)
    (can? :read, collection_resource) || collection_resource.can_view || collection_resource.can_edit || (can? :edit, collection_resource.collection.organization)
  end
end
