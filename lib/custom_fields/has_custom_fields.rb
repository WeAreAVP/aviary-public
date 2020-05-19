module CustomFields
  # HasCustomFields
  module HasCustomFields
    extend ActiveSupport::Concern

    included do
      has_one :field_settings,
              class_name: 'CustomFields::Settings',
              dependent: :destroy,
              as: :customizable

      has_one :field_values,
              class_name: 'CustomFields::Values',
              dependent: :destroy,
              as: :customizable

      before_save :save_custom_attributes
      @parent_entity = nil
      @field_types = nil
      include CommonHelper
    end

    def dynamic_attributes
      attrs = {}
      attrs['fields'] = if persisted? && any_dynamic_attributes?
                          if should_resolve_persisted?
                            resolve_combined
                          else
                            resolve_from_db
                          end
                        else
                          resolve_from_provider
                        end
      setting = get_settings(attrs['fields'])
      attrs['settings'] = setting[0]
      attrs['fields'] = setting[1]
      attrs['values'] = get_dynamic_values(setting[0][self.class.name])
      attrs
    end

    def all_fields
      list_all_fields = {}
      tombstones = []
      default_tombstone = []
      dynamic_attrs = dynamic_attributes
      dynamic_attrs['settings'].each do |key, value|
        if @parent_entity && key == @parent_entity.class.name
          next
        end
        if list_all_fields[key].nil?
          list_all_fields[key] = []
        end
        value.each do |setting|
          row = {}
          field_index = search_int_value(dynamic_attrs['fields'], 'id', setting['field_id'].to_i)
          value_index = search_int_value(dynamic_attrs['values'], 'field_id', setting['field_id'].to_i)
          cfield = dynamic_attrs['fields'][field_index]
          cvalue = value_index.present? ? dynamic_attrs['values'][value_index] : nil
          tombstone = ActiveModel::Type::Boolean.new.cast(setting['is_tombstone'])
          visible = ActiveModel::Type::Boolean.new.cast(setting['is_visible'])
          row['settings'] = { is_tombstone: tombstone, is_visible: visible }
          row['values'] = []
          unless cvalue.nil?
            row['values'] = cvalue['values']
          end
          row['field'] = cfield
          if row['values'].length >= 1 && (row['values'][0]['value'].present? || row['values'][0]['vocab_value'].present?)
            if tombstone
              tombstones << row
            end
            if %w[agent date duration].include? row['field'].system_name
              default_tombstone << row
            end
          end
          list_all_fields[key] << row
        end
      end
      list_all_fields['tombstones'] = tombstones
      list_all_fields['default_tombstone'] = default_tombstone
      list_all_fields
    end

    def custom_field_value(system_name)
      fields = all_fields
      field_index = fields[self.class.name].index { |hash| hash['field'].system_name == system_name }
      fields[self.class.name][field_index]['values']
    end

    def dynamic_attributes_loaded?
      @dynamic_attributes_loaded ||= false
    end

    def respond_to?(method_name, include_private = false)
      if super
        true
      else
        load_dynamic_attributes unless dynamic_attributes_loaded?
        dynamic_attributes['fields'].find { |attr| attr.system_name == method_name.to_s.delete('=') }.present?
      end
    end

    def method_missing(method_name, *arguments, &block)
      if dynamic_attributes_loaded?
        super
      else
        load_dynamic_attributes
        send(method_name, *arguments, &block)
      end
    end

    def create_update_dynamic(new_field, id = nil, settings = nil)
      if id.nil?
        random = Time.now.to_s + rand(10_000).to_s
        new_field[:system_name] = random unless new_field[:system_name].present?
        field_def = CustomFields::FieldDefinition.new(new_field[:system_name], new_field)
        field = CustomFields::Field.create(field_def.as_json)
        field.save
        current = dynamic_attributes['settings']
        current[field.source_type] = [] if current[field.source_type].nil?
        current[field.source_type] << if settings.nil?
                                        CustomFields::FieldSettingsDefinition.new(field_id: field.id, is_visible: true, is_tombstone: false).as_json
                                      else
                                        CustomFields::FieldSettingsDefinition.new(field_id: field.id, is_visible: settings[:is_visible], is_tombstone: settings[:is_tombstone]).as_json
                                      end
        update_field_settings(current[field.source_type], field.source_type)
      else
        field = CustomFields::Field.find_by_id(id)
        field.update(new_field.as_json)
      end
      field.id
    end

    def delete_dynamic(field_id)
      field = CustomFields::Field.find_by_id(field_id)
      current = dynamic_attributes['settings']
      index = search_int_value(current[field.source_type], 'field_id', field.id)
      if index
        current[field.source_type].delete_at(index)
      end
      update_field_settings(current[field.source_type], field.source_type)
      field.destroy
    end

    def update_field_settings(new_settings, type = nil)
      ## TODO manage for collection resource, update settings of specific type
      current = dynamic_attributes['settings']
      if type.nil?
        current[self.class.name] = new_settings
      else
        current[type] = new_settings
      end
      @field_setting = CustomFields::Settings.find_or_initialize_by(customizable_id: id, customizable_type: self.class.name)
      @field_setting.update(settings: current.to_json)
    end

    def batch_update_values(new_values, overwrite = false)
      @field_values = CustomFields::Values.find_or_initialize_by(customizable_id: id, customizable_type: self.class.name)
      all_values = new_values
      unless overwrite
        all_values = @field_values.present? && @field_values.values.present? ? JSON.parse(@field_values.values) : []
        new_values.as_json.each do |val|
          all_values = single_value_update(val['field_id'], val['values'], all_values)
        end
      end
      if @field_values
        @field_values.update(values: all_values.to_json)
      else
        @field_values.assign_attributes(values: all_values.to_json)
        @field_values.save
      end
    end

    def update_field_value(system_name, values)
      field = CustomFields::Field.find_by(system_name: system_name, source_type: self.class.name)
      batch_update_values([{ field_id: field.id, values: values }])
    end

    private

    def single_value_update(field_id, values, current_list)
      current = current_list.to_a
      value_index = search_int_value(current, 'field_id', field_id.to_i)
      if value_index.nil?
        field_value = { field_id: field_id, values: values }.as_json
        current << field_value
      else
        field_value = current_list[value_index]
        field_value['values'] = values
        current[value_index] = field_value
      end
      current
    end

    def should_resolve_persisted?
      value = CustomFields.configuration.resolve_persisted
      case value
      when TrueClass, FalseClass
        value
      when Proc
        value.call(self)
      else
        raise "Invalid configuration for resolve_persisted. Value should be Bool or Proc, got #{value.class}"
      end
    end

    def any_dynamic_attributes?
      if !any_dynamic_initializer? || (any_dynamic_initializer? && @field_types.nil?)
        CustomFields::Field.where(source_type: self.class.name).any?
      else
        CustomFields::Field.where(source_type: @field_types).any?
      end
    end

    def resolve_combined
      fields = configured_provider_fields
      attributes = []
      fields.each do |attribute|
        field = CustomFields::Field.find_by(system_name: attribute.system_name, source_type: attribute.source_type, is_custom: false)
        if !field.present?
          field = CustomFields::Field.find_or_initialize_by(attribute.as_json)
          field.save
        elsif field.is_vocabulary
          existing_vocab = JSON.parse(field.vocabulary)
          provider_vocab = JSON.parse(attribute.vocabulary)
          if existing_vocab.sort != provider_vocab.sort
            new_vocab = (existing_vocab + provider_vocab).delete_if(&:blank?).uniq
            attribute.vocabulary = new_vocab.to_json
            field.update(attribute.as_json)
          end
        end
        attributes << field
      end
      attributes
    end

    def resolve_from_db
      fields = if !any_dynamic_initializer? || (any_dynamic_initializer? && @field_types.nil?)
                 CustomFields::Field.where(source_type: self.class.name, is_custom: false)
               else
                 CustomFields::Field.where(source_type: @field_types, is_custom: false)
               end
      fields
    end

    def any_dynamic_initializer?
      if self.class.method_defined? :init_dynamic_initializer
        @parent_entity = init_dynamic_initializer[:parent_entity] unless init_dynamic_initializer[:parent_entity].nil?
        @field_types = init_dynamic_initializer[:field_types] unless init_dynamic_initializer[:field_types].nil?
        return true
      end
      false
    end

    def resolve_from_provider
      fields = configured_provider_fields
      attributes = []
      fields.each do |attribute|
        field = CustomFields::Field.find_by(system_name: attribute.system_name, source_type: attribute.source_type, is_custom: false)
        unless field.present?
          field = CustomFields::Field.find_or_initialize_by(attribute.as_json)
          field.save
        end
        attributes << field
      end
      attributes
    end

    def get_settings(attributes)
      attributes = attributes.to_a
      settings = {}
      ## TODO need to update for resource
      entity_id = id
      entity_name = self.class.name
      if any_dynamic_initializer? && !@parent_entity.nil?
        entity_id = @parent_entity.id
        entity_name = @parent_entity.class.name
      end
      db_settings = CustomFields::Settings.find_by(customizable_id: entity_id, customizable_type: entity_name)
      if entity_id.nil? || db_settings.nil?
        attributes.each do |field|
          if settings[field.source_type].nil?
            settings[field.source_type] = []
          end
          settings[field.source_type] << CustomFields::FieldSettingsDefinition.new(field_id: field.id, is_visible: true, is_tombstone: false).as_json
        end
      else
        settings = JSON.parse(db_settings.settings)
        if any_dynamic_initializer? && !@parent_entity.nil?
          child_settings = settings[self.class.name]
          child_settings.each do |entity|
            attributes << CustomFields::Field.find(entity['field_id']) if search_int_value(attributes, 'id', entity['field_id']).nil?
          end
        else
          settings.each_value do |entity|
            entity.each do |field|
              attributes << CustomFields::Field.find(field['field_id']) if search_int_value(attributes, 'id', field['field_id']).nil?
            end
          end
        end
      end
      [settings, attributes]
    end

    def get_dynamic_values(attributes)
      values = []
      unless attributes.nil?
        db_settings = CustomFields::Values.find_by(customizable_id: id, customizable_type: self.class.name)
        if !persisted? || db_settings.nil?
          attributes.each do |field|
            field = field.as_json unless field.class == Hash
            values << CustomFields::FieldValuesDefinition.new(field_id: field['field_id']).as_json
          end
        else
          ## Max length: 1006152
          values = JSON.parse(db_settings.values)
          attributes.each do |field|
            field = field.as_json unless field.class == Hash
            values << CustomFields::FieldValuesDefinition.new(field_id: field['field_id']).as_json if search_int_value(values, 'field_id', field['field_id'].to_i).nil?
          end
        end
      end
      values
    end

    def generate_accessors(field)
      define_singleton_method("custom_#{field.id}") do
        _custom_fields[field.id]
      end
    end

    def _custom_fields
      @_custom_fields ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def load_dynamic_attributes
      dynamic_attr = dynamic_attributes
      values = dynamic_attr['values']
      values.each do |ticket_field|
        ticket_field = ticket_field.as_json unless ticket_field.class == Hash
        field = CustomFields::Field.find_by_id(ticket_field['field_id'])
        if field
          _custom_fields[field.id] = ticket_field['values']
          generate_accessors field
        end
      end
      @dynamic_attributes_loaded = true
    end

    def configured_provider_fields
      entity = self
      if any_dynamic_initializer? && !@parent_entity.nil?
        entity = @parent_entity
      end
      if Rails.env.test?
        begin
          CustomFields::TestProvider.new(entity).call
        rescue
          CustomFields.configuration.provider_class.new(entity).call
        end
      else
        CustomFields.configuration.provider_class.new(entity).call
      end
    end

    def save_custom_attributes
      test = unless persisted?
               dynamic_attrs = dynamic_attributes
               if any_dynamic_initializer? && @parent_entity.nil?
                 @entity_settings = CustomFields::Settings.find_or_initialize_by(customizable_id: id, customizable_type: self.class.name)
                 @entity_settings.assign_attributes(settings: dynamic_attrs['settings'].to_json)
                 @entity_settings.save
               end
               if any_dynamic_initializer? && (@parent_entity.nil? || (!@parent_entity.nil? && persisted?))
                 @entity_values = CustomFields::Values.find_or_initialize_by(customizable_id: id, customizable_type: self.class.name)
                 @entity_values.assign_attributes(values: dynamic_attrs['values'].to_json)
                 @entity_values.save
               end
             end
      test
    end
  end
end
