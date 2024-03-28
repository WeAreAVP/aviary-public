### Script to add Resource Fields to ALl Orgs

```ruby
def change
  @org_field_settings = Aviary::FieldManagement::OrganizationFieldManager.new
  field = {
    'label' => 'Playlist',
    'system_name' => 'playlist',
    'field_type' => 'string',
    'is_required' => false,
    'is_public' => false,
    'is_default' => true,
    'is_vocabulary' => false,
    'vocabulary' => [],
    'help_text' => '',
    'is_repeatable' => false,
    'field_configuration' => { 'special_purpose' => true, 'visible_at' => 'resource_listing,resource_search' },
    'field_level' => 'resource',
    'sort_order' => 29,
    'description_display' => false,
    'resource_table_display' => false,
    'resource_table_search' => false,
    'solr_display_column' => 'playlist_ims',
    'solr_search_column' => 'playlist_ims',
    'resource_table_sort_order' => 29,
    'search_display' => true,
    'search_sort_order' => 29
  } 
  Organization.all.each do |org|
    if org.organization_field.try(:[], 'resource_fields').present?
      fields = org.organization_field['resource_fields']
      field['sort_order'] = field['resource_table_sort_order'] = field['search_sort_order'] = fields.count
      @org_field_settings.add_field_to_organization(fields, field, org, 'resource_fields', 'playlist')

      org.collection_fields_and_values.each do |f_and_y|
        f_and_y.resource_fields['playlist'] = {"status" => true, "tombstone" => false, "sort_order" => f_and_y.resource_fields.count }
        f_and_y.save
      end
    end
  end
end
