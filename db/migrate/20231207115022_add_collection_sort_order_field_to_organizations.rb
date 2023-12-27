class AddCollectionSortOrderFieldToOrganizations < ActiveRecord::Migration[6.1]
  def change
    Organization.all.each do  |org|
      all_fields = org.organization_field&.resource_fields.deep_dup
      next unless (all_fields.present?)
      system_name = 'Collection Sort Order'.parameterize.underscore
      all_fields[system_name] = {
        'label' => 'Collection Sort Order',
        'help_text' => 'Define sort order of resources within collection',
        'is_public' => false,
        'field_type' => 'integer',
        'is_default' => true,
        'is_repeatable' => false,
        'is_internal_only' => true,
        'field_level' => 'resource',
        'is_required' => false,
        'system_name' => system_name,
        'is_vocabulary' => false,
        'vocabulary' => [],
        'field_configuration' => { special_purpose: true, visible_at: 'resource_listing' },
        'sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'description_display' => false,
        'resource_table_display' => true,
        'resource_table_search' => false,
        'search_display' => false,
        'solr_display_column' => 'collection_sort_order_ss',
        'solr_search_column' => 'collection_sort_order_ss',
        'resource_table_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'search_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
      }
      org.organization_field.resource_fields = all_fields
      org.organization_field.save
    end
  end
end
