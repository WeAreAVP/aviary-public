module CustomFields
  # FieldSettingsDefinition
  class FieldSettingsDefinition
    attr_reader :field_id, :is_visible, :is_tombstone

    def initialize(params = {})
      options = params.dup
      @field_id = options.delete(:field_id)
      @is_visible = options.delete(:is_visible) || true
      @is_tombstone = options.delete(:is_tombstone) || false

      # custom attributes from Provider
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end
  end
end
