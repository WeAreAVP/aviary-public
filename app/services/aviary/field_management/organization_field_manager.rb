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
  module FieldManagement
    # OrganizationFieldManagement Class for Organization Field Management and saving and fetching information

    # OrganizationFieldManager
    class OrganizationFieldManager < BasedFieldManager
      include OrganizationHelper

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
            fields[single_collection_field['system_name'].downcase][key] = value if fields[single_collection_field['system_name'].downcase].present?
            if key == 'is_internal_only' && single_collection_field['system_name'].downcase != 'collection_sort_order' &&
               acts_as_default(fields[single_collection_field['system_name'].downcase])

              fields[single_collection_field['system_name'].downcase][key] = false
            end
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

      # This method allow you to query resource fields like an SQL
      # Currently it only supports '=', '!=' and 'LIKE'
      # In case of 'LIKE', the match is case insensitive
      # It supports AND, OR and NOT logical operators
      # Example:
      #   org_field_manager = OrganizationFieldManager.new
      #   org_field_manager.where(organization, "label = Worm Factor 2 OR system_name = publisher AND is_default = false", 'resource_fields')
      # OR
      #   org_field_manager.where(organization, "label = Worm Factor 2 OR system_name = publisher AND is_default LIKE %als%", 'resource_fields')
      def where(organization, filter_statement, fields_type = 'collection_fields')
        return {} if filter_statement.empty?

        filter_statement = filter_statement.split(/(?<= AND)|(?<= OR)|(?<= NOT)/)
        matchers = %w[LIKE = !=]

        fields = organization.organization_field.send(fields_type)
        fields.select do |_name, value|
          result = true
          logic = 'AND'

          filter_statement.each do |condition|
            condition = condition.split(/(?<= = )|(?<= != )|(?<= LIKE )/)
            condition[1] = condition[1].split(/ (?=AND)| (?=OR)| (?=NOT)/)
            condition[0] = condition[0].split(' ')

            unless matchers.include?(condition[0][1])
              raise "Incompatible matcher detected. Only '=', '!=' and 'LIKE' are allowed"
            end

            current_result = case condition[0][1]
                             when '='
                               value[condition[0][0]].to_s == condition[1][0]
                             when '!='
                               value[condition[0][0]].to_s != condition[1][0]
                             when 'LIKE'
                               value[condition[0][0]].to_s =~ /^#{condition[1][0].gsub('%', '.*')}$/i
                             end

            result = case logic
                     when 'AND'
                       result && current_result
                     when 'OR'
                       result || current_result
                     when 'NOT'
                       result && !current_result
                     end

            logic = condition[1][1].present? ? condition[1][1] : 'OR'
            unless %w[AND OR NOT].include?(logic)
              raise "Invalid logical operator detected, Only 'AND', 'OR' and 'NOT' are allowed"
            end
          end

          result
        end
      end
    end
  end
end
