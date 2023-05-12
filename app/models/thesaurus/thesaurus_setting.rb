# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Thesaurus
  class ThesaurusSetting < ApplicationRecord
    belongs_to :organization
  end
end
