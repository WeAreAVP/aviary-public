# services/aviary/field_management/organization_field_manager.rb
#
# Module Aviary::OrganizationFieldManagement
# The module is written to for Organization Field Management and saving and fetching information in the Aviary system
#
# Author::    Furqan wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

module Aviary
  # OrganizationFieldManagement Class for Organization Field Management and saving and fetching information
  module FieldManagement
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
            collection.collection_fields_and_value.update(type.to_s => collection_fields) if collection.collection_fields_and_value[type.to_sym].blank?
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
  end
end
