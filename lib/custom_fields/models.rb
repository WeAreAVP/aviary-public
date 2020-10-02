module CustomFields
  # Field
  class Field < ActiveRecord::Base
    self.table_name = 'field_manager'
    validates :system_name, presence: true

    def self.create_or_update_vocabularies(field_id, vocab_term)
      field = Field.find_by_id(field_id)
      vocabularies = field.vocabulary.present? ? JSON.parse(field.vocabulary) : []
      in_vocab = vocab_term.strip.in?(vocabularies) ? true : false
      vocabularies << vocab_term.strip unless in_vocab
      field.update(is_vocabulary: 1, vocabulary: vocabularies) unless in_vocab
    end

    # TypeInformation
    class TypeInformation
      DROPDOWN = 1
      CHECKBOX = 2
      DATE = 3
      TEXT = 4
      TOKEN = 5
      TEXTAREA = 6

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

  # Settings
  class Settings < ActiveRecord::Base
    belongs_to :customizable, polymorphic: true
    self.table_name = 'field_settings'
    after_save :propagate_fields_org_wide
    after_destroy :propagate_fields_org_wide

    def propagate_fields_org_wide
      customizable.organization.update_field_settings if customizable_type == 'Collection'
    end
  end

  # Values
  class Values < ActiveRecord::Base
    belongs_to :customizable, polymorphic: true
    self.table_name = 'field_values'
  end
end
