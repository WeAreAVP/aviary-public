# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Thesaurus
  # ThesaurusTerms
  class ThesaurusTerms < ApplicationRecord
    belongs_to :thesaurus_information, class_name: 'Thesaurus::Thesaurus'
  end
end
