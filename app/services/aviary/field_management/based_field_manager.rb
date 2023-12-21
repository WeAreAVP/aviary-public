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
    # BasedFieldManager
    class BasedFieldManager
      def sort_fields(fields, sort_by)
        fields.sort_by { |_key, value| value[sort_by].present? ? value[sort_by] : 999 }.to_h if fields.present?
      end
    end
  end
end
