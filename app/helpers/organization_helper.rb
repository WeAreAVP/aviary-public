# frozen_string_literal: true

# OrganizationHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module OrganizationHelper
  def acts_as_default(field)
    return field['is_default'] if field['is_default'].present? && field['is_default'].to_s.to_boolean?
    field['field_configuration'].present? && field['field_configuration']['act_as_default'].present? ? field['field_configuration']['act_as_default'].to_s.to_boolean? : false
  end
end
