# services/aviary/field_management/organization_field_manager.rb
#
# Module Aviary::OrganizationFieldManagement
# The module is written to for Organization Field Management and saving and fetching information in the Aviary system
#
# Author::    Furqan wasi  (mailto:furqan@weareavp.com)

module Aviary
  module FieldManagement
    # OrganizationFieldManagement Class for Organization Field Management and saving and fetching information

    # BasedFieldManager
    class BasedFieldManager
      def sort_fields(fields, sort_by)
        fields.sort_by { |_key, value| value[sort_by].present? ? value[sort_by] : 999 }.to_h if fields.present?
      end
    end

    # OrganizationFieldManager
    class OrganizationFieldManager < BasedFieldManager
      def organization_field_settings(organization, value_for = nil, fields_type = 'collection_fields', sort_by = 'sort_order', fetch_type = 'hash')
        return nil unless organization.present?
        organization.assign_fields_to_organization
        return nil if organization.blank? || fields_type.blank?
        return organization.organization_field[fields_type.to_sym][value_for] if value_for.present?

        if fetch_type == 'object'
          organization.organization_field
        else
          sort_fields(organization.organization_field[fields_type.to_sym], sort_by)
        end
      rescue StandardError
        fields_information = Rails.configuration.default_fields['fields']
        org_field = OrganizationField.find_or_create_by(organization: Organization.first)
        org_field.update(collection_fields: fields_information['collection'], resource_fields: fields_information['resource'])
        org_field[fields_type.to_sym]
      end

      def field_default_settings(system_name)
        resource = Rails.configuration.default_fields['fields']['resource']
        return resource[system_name] if resource[system_name].present?
        {}
      end

      def add_field_to_organization(fields, updated_values, organization, type, system_name)
        fields[system_name] = updated_values
        organization.organization_field[type] = fields
        organization.organization_field.save
      end

      def update_field_settings(fields, updated_values, organization, type)
        updated_values.each_with_index do |(_index, single_collection_field), _key|
          single_collection_field.each do |key, value|
            value = value.to_i if key.include? 'sort'
            fields[single_collection_field['system_name']][key] = value
          end
        end
        organization.organization_field[type] = fields
        organization.organization_field.save
      end

      def update_create_field(organization, fields_type, system_name, label)
        all_fields_settings = organization_field_settings(organization, nil, fields_type, 'sort_order', 'object')
        fields_settings = all_fields_settings[fields_type.to_sym]
        if fields_settings[system_name].present?
          fields_settings[system_name]
        else

          type_field = Aviary::SolrIndexer.field_type_finder(fields_type)
          fields_settings[system_name] = {
            'label' => label,
            'help_text' => nil,
            'is_public' => false,
            'field_type' => fields_type,
            'is_default' => false,
            'sort_order' => fields_settings.length + 1,
            'vocabulary' => [],
            'field_level' => fields_type == 'resource_fields' ? 'resource' : 'collection',
            'is_required' => false,
            'system_name' => label.parameterize.underscore,
            'is_repeatable' => false,
            'is_vocabulary' => false,
            'search_display' => false,
            'search_sort_order' => fields_settings.length + 1,
            'description_display' => true,
            'field_configuration' => {},
            'solr_search_column' => 'custom_field_values_' + system_name + type_field,
            'solr_display_column' => 'custom_field_values_' + system_name + type_field,
            'resource_table_search' => false,
            'resource_table_display' => false,
            'resource_table_sort_order' => fields_settings.length + 1
          }
        end
        all_fields_settings[fields_type.to_sym] = fields_settings
        all_fields_settings.save
      end

      def delete_field(organization, field_system_name, fields_type = 'collection_fields')
        fields = organization_field_settings(organization, nil, fields_type, 'sort_order', 'object')
        fields[fields_type.to_sym].delete(field_system_name)
        fields.save
      end
    end

    # CollectionFieldManager
    class CollectionFieldManager < BasedFieldManager
      def collection_resource_field_settings(collection, type)
        unless collection.collection_fields_and_value.present? && collection.collection_fields_and_value.resource_fields.present? && collection.collection_fields_and_value.collection_fields.present?
          org_field = OrganizationFieldManager.new.organization_field_settings(collection.organization, nil, type, 'sort_order')
          collection_fields = {}
          if org_field.present?
            org_field.each_with_index do |(system_name, single_collection_field), index|
              if single_collection_field['is_default'].to_s.to_boolean? && system_name.present?
                collection_fields[system_name] = { status: true, tombstone: false, sort_order: index }
              end
            end
          end

          if collection.collection_fields_and_value.present?
            collection.collection_fields_and_value.update_attributes(type.to_s => collection_fields) if collection.collection_fields_and_value[type.to_sym].blank?
          else
            obj = CollectionFieldsAndValue.create(collection: collection, organization: collection.organization)
            obj[type.to_sym] = collection_fields
            obj.save
          end
          sort_fields(collection.collection_fields_and_value[type.to_sym], 'sort_order')
          collection.collection_fields_and_value.save
        end
        collection.collection_fields_and_value
      end

      def update_field_settings(updated_values, collection, type = 'resource_fields')
        fields = collection.collection_fields_and_value[type.to_sym]
        updated_values.each_with_index do |(_index, single_collection_field), _key|
          single_collection_field.each do |key, value|
            value = value.to_i if key.include? 'sort'
            fields[single_collection_field['system_name']][key] = value
          end
        end
        collection.collection_fields_and_value[type.to_sym] = fields
        collection.collection_fields_and_value.save
      end

      def update_field_settings_collection(update_information, collection, type = 'resource_fields', sort_order = nil)
        if collection.class.name == 'ActiveRecord::Relation'
          collection.each do |single_collection|
            update_collection_fields(single_collection, type, update_information, sort_order)
          end
        else
          update_collection_fields(collection, type, update_information, sort_order)
        end
      end

      def delete_field(collection, type, field_system_name)
        fields = collection_resource_field_settings(collection, type)
        fields[type.to_sym].delete(field_system_name)
        fields.save
      end

      private

      def update_collection_fields(single_collection, type, update_information, sort_order = nil)
        collection_fields = collection_resource_field_settings(single_collection, type)
        fields = collection_fields[type.to_sym]
        update_information['sort_order'] = sort_order.present? ? sort_order : fields.keys.count + 1

        fields[update_information['system_name']] = update_information.except('system_name')
        collection_fields[type.to_sym] = fields
        collection_fields.save
      end
    end

    # FieldManager
    class FieldManager
      attr_accessor :field_settings, :key

      def initialize(field_settings, key)
        map_field_settings(field_settings, key)
      end

      def map_field_settings(field_settings, key)
        self.field_settings = field_settings
        self.key = key
      end

      def info_of_attribute(attribute)
        field_settings[attribute.to_s] if attribute.present? && field_settings[attribute.to_s].present?
      end

      def field_key
        key
      end

      def label
        field_settings['label']
      end

      def system_name
        field_settings['system_name']
      end

      def editor
        field_settings['editor']
      end

      def required?
        field_settings['is_required'].present? ? field_settings['is_required'].to_s.to_boolean? : false
      end

      def public?
        field_settings['is_public'].present? ? field_settings['is_public'].to_s.to_boolean? : false
      end

      def default?
        field_settings['is_default'].present? ? field_settings['is_default'].to_s.to_boolean? : false
      end

      def vocabulary?
        field_settings['is_vocabulary'].present? ? field_settings['is_vocabulary'].to_s.to_boolean? : false
      end

      def vocabulary_list
        field_settings['vocabulary']
      end

      def help_text
        field_settings['help_text']
      end

      def repeatable?
        field_settings['is_repeatable'].present? ? field_settings['is_repeatable'].to_s.to_boolean? : false
      end

      def field_configuration
        field_settings['field_configuration']
      end

      def field_level
        field_settings['field_level']
      end

      def sort_order_on_detail_page
        field_settings['sort_order'].present? ? field_settings['sort_order'].to_i : 999
      end

      def should_display_on_detail_page
        field_settings['description_display'].present? ? field_settings['description_display'].to_s.to_boolean? : false
      end

      def should_display_on_resource_table
        field_settings['resource_table_display'].present? ? field_settings['resource_table_display'].to_s.to_boolean? : false
      end

      def should_search_on_resource_table
        field_settings['resource_table_search'].present? ? field_settings['resource_table_search'].to_s.to_boolean? : false
      end

      def solr_display_column_name
        field_settings['solr_display_column']
      end

      def tombstone?
        field_settings['is_tombstone'].present? ? field_settings['is_tombstone'].to_s.to_boolean? : false
      end

      def solr_search_column_name
        field_settings['solr_search_column']
      end

      def sort_order_on_resource_table
        field_settings['resource_table_sort_order'].present? ? field_settings['resource_table_sort_order'].to_i : 999
      end

      def should_display_on_search_page
        field_settings['search_display'].present? ? field_settings['search_display'].to_s.to_boolean? : false
      end

      def sort_order_on_search_page
        field_settings['search_sort_order'].present? ? field_settings['search_sort_order'].to_i : 999
      end
    end
  end
end
