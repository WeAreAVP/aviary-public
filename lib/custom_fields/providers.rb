# CustomFields Providers
module CustomFields
  # NullProvider
  class NullProvider
    def initialize(model); end

    def call
      []
    end
  end

  # TestProvider
  class TestProvider
    def initialize(model)
      @model = model
    end

    def call
      case @model
      when Author
        [
          CustomFields::FieldDefinition.new('age', column_type: 4, source_type: 'Author'),
          CustomFields::FieldDefinition.new('qualification', column_type: 4, source_type: 'Author'),
          CustomFields::FieldDefinition.new('gender', column_type: 1, source_type: 'Author'),
          CustomFields::FieldDefinition.new('publisher', column_type: 4, source_type: 'Book'),
          CustomFields::FieldDefinition.new('genre', column_type: 4, source_type: 'Book'),
          CustomFields::FieldDefinition.new('language', column_type: 1, source_type: 'Book')
        ]
      else
        []
      end
    end
  end
end
