class AddCreatedAtToOrganizationsResourceFields < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do  |org|
      all_fields = org.organization_field&.resource_fields.deep_dup
      next unless (all_fields.present?)
      system_name = 'Created At'.parameterize.underscore
      all_fields[system_name] = {
        'label' => 'Created At',
        'help_text' => 'Show created at',
        'is_public' => false,
        'field_type' => 'text',
        'is_default' => true,
        'is_repeatable' => true,
        'field_level' => 'resource',
        'is_required' => false,
        'system_name' => system_name,
        'is_vocabulary' => false,
        'vocabulary' => [],
        'field_configuration' => { special_purpose: true, visible_at: 'resource_listing' },
        'sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'description_display' => true,
        'resource_table_display' => true,
        'resource_table_search' => true,
        'search_display' => true,
        'solr_display_column' => 'created_at_ss',
        'solr_search_column' => '',
        'resource_table_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'search_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1
      }
      org.organization_field.resource_fields = all_fields
      org.organization_field.save
    end
  end
end
