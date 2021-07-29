# CollectionFieldsAndValue
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class CollectionFieldsAndValue < ApplicationRecord
  belongs_to :organization
  belongs_to :collection
end
