# FieldValuesDefinition
module CustomFields
  # FieldValuesDefinition
  class FieldValuesDefinition
    attr_reader :field_id, :values

    def initialize(params = {})
      options = params.dup
      @field_id = options.delete(:field_id)
      @values = options.delete(:values) || [{ value: '', vocab_value: '' }]

      options.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end
  end
end
