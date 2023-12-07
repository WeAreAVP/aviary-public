class AddCollectionSortOrderFieldToOrganizations < ActiveRecord::Migration[6.1]
  include Aviary::FieldManagement

  def change
    @collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new

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
        'field_configuration' => {},
        'sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'description_display' => true,
        'resource_table_display' => true,
        'resource_table_search' => true,
        'search_display' => true,
        'solr_display_column' => 'description_collection_sort_order_is',
        'solr_search_column' => 'description_collection_sort_order_search_texts',
        'resource_table_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
        'search_sort_order' => org.organization_field.resource_fields.keys.count.to_i + 1,
      }
      org.organization_field.resource_fields = all_fields
      org.organization_field.save

      org.collections.each do |col|
        update_information = {
          "system_name" => system_name,
          "status" => true,
          "tombstone" => false,
          "sort_order" => 0
        }

        @collection_field_manager.update_field_settings_collection(
          update_information, col, 'resource_fields'
        )
      end
    end
  end
end
