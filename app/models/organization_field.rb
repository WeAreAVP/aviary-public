# OrganizationFields
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OrganizationField < ApplicationRecord
  belongs_to :organization
  # TypeInformation
  class TypeInformation
    DROPDOWN = 'dropdown'.freeze
    CHECKBOX = ''.freeze
    DATE = 'date'.freeze
    TEXT = 'text'.freeze
    TOKEN = 'tokens'.freeze
    TEXTAREA = 'editor'.freeze

    NAMES = { DROPDOWN => 'dropdown', DATE => 'date', TEXT => 'text', TOKEN => 'tokens', TEXTAREA => 'editor' }.freeze

    def self.for_select
      NAMES.invert.to_a
    end

    def self.fetch_type(field_type)
      NAMES[field_type]
    end
  end

  def fetch_type
    TypeInformation.fetch_type(column_type)
  end
end
