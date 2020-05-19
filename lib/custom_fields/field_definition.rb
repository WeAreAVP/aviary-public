module CustomFields
  # FieldDefinition
  class FieldDefinition
    attr_reader :label, :system_name, :is_vocabulary, :vocabulary, :column_type, :default, :help_text, :source_type, :is_required, :is_repeatable, :is_public, :is_custom, :field_value, :field_vocab, :dropdown_options

    def initialize(system_name, params = {})
      options = params.dup
      @system_name = (options.delete(:system_name) || system_name)
      @label = options[:label] || system_name.titleize
      @column_type = options[:column_type] || 4
      @default = options[:default] || 1
      @is_required = options[:is_required] || false
      @is_vocabulary = options[:is_vocabulary] || 0
      @vocabulary = options[:vocabulary] || ''
      @help_text = options[:help_text] || ''
      @is_repeatable = options[:is_repeatable] || 1
      @is_public = options[:is_public] || true
      @is_custom = options[:is_custom] || false
      @dropdown_options = options[:dropdown_options] || ''

      # custom attributes from Provider
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.send(:attr_accessor, key)
        options.delete(key)
      end
    end
  end
end
