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

      def field_type
        field_settings['field_type']
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

      def dropdown_options
        field_settings['field_configuration'].present? && field_settings['field_configuration']['dropdown_options'] ? field_settings['field_configuration']['dropdown_options'] : []
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
