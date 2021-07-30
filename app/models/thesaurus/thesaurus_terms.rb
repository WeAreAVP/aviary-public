module Thesaurus
  # ThesaurusTerms
  class ThesaurusTerms < ApplicationRecord
    belongs_to :thesaurus_information, class_name: 'Thesaurus::Thesaurus'
  end
end
