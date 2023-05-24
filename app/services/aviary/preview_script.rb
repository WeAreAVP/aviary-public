# PreviewScript
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class PreviewScript
  def initialize(collection, params = nil, resource_fields = nil, resource_columns_collection = nil)
    @params = params
    @collection = collection
    @resource_fields = resource_fields
    @resource_columns_collection = resource_columns_collection
  end

  def data_hash(resource, _collection_fields = nil)
    title = resource.present? ? resource.title : 'This is the Resource Title'

    data_hash = { 'resource_title' => title, 'collection_title' => @collection.title, 'organization_title' => @collection.organization.name }
    tombstone_hash = {}
    if @resource_columns_collection.present?
      @resource_columns_collection.each_with_index do |(system_name, single_field), index|
        field_settings = Aviary::FieldManagement::FieldManager.new(@resource_fields[system_name], system_name)
        next if @resource_fields[system_name].blank? || system_name.blank? || !@resource_fields[system_name]['description_display'].to_s.to_boolean? || !single_field['status'].to_s.to_boolean? && field_settings.should_display_on_detail_page

        value_array = []
        is_tombstone = false
        if single_field['tombstone'].to_s.to_boolean?
          is_tombstone = single_field['tombstone']
        end

        flag_check = resource.present? && resource.resource_description_value.present? && resource.resource_description_value.resource_field_values.present? && resource.resource_description_value.resource_field_values[system_name]
        fields_value = if flag_check && resource.resource_description_value.resource_field_values[system_name]['values']
                         values = resource.resource_description_value.resource_field_values[system_name]['values']
                         values.present? ? values : preview_hash_switch(system_name)
                       else
                         preview_hash_switch(system_name)
                       end

        fields_value.each do |field|
          value_array << if field.is_a?(String)
                           { 'value' => field }
                         else
                           { 'is_vocabulary' => field_settings.vocabulary?, 'vocabulary_value' => field['vocab_value'],
                             'value' => field['value'].present? ? field['value'] : preview_hash_switch(system_name).first, 'token' => field_settings.info_of_attribute('field_type'), token_value: field['value'].to_s.split(',') }
                         end
        end

        tombstone_hash[(index + 1)] = { system_name => [{ 'is_tombstone' => is_tombstone, 'is_visible' => field_settings.should_display_on_detail_page, 'label' => field_settings.label }, value_array] }
        data_hash['fields'] = tombstone_hash
      end
    end
    data_hash
  end

  def update_data_hash(data_hash)
    total = data_hash.count
    data_hash_fields = {}
    data_hash_fields['fields'] = data_hash['fields']
    if @params['new_custom_value']['new_custom_field'].present?
      data_hash_fields['fields'] ||= {}
      data_hash_fields['fields'][total + 1] = { @params['new_custom_value']['new_custom_field'] => [{ 'is_tombstone' => false, 'is_visible' => true },
                                                                                                    [{ 'value' => preview_hash_switch(@params['new_custom_value']['new_custom_field']).first }]] }
    end
    data_hash_fields['collection_title'] = @params['collection_title']
    data_hash_fields['resource_title'] = data_hash['resource_title']
    data_hash_fields['organization_title'] = data_hash['organization_title']
    data_hash_fields['fields']['resource'] ||= {}
    unless data_hash_fields['fields']['resource'].count.zero?
      data_hash_fields['fields'].each do |_k, v|
        if v.class.to_s == 'Hash'
          v.each do |h_k, h_v|
            h_v.first['is_tombstone'] = if @params['tombstone'].present?
                                          @params['tombstone'].include?(h_k)
                                        else
                                          false
                                        end
            if @params['visible'].present?
              h_v.first.merge!('is_visible' => @params['visible'].include?(h_k))
            else
              h_v.first.merge!('is_visible' => false)
            end
          end
        end
      end
    end
    if @params['sort_order']['sort_data'].present?
      @params['sort_order']['sort_data'].each do |k, v|
        (1..total).each do |i|
          if data_hash_fields['fields'][i].present? && data_hash_fields['fields'][i].first.first == k
            value = data_hash_fields['fields'][i]
            abc = data_hash_fields['fields'][v.to_i]
            data_hash_fields['fields'][v.to_i] = value
            data_hash_fields['fields'].merge!(i => abc)
          end
        end
      end
    end
    data_hash_fields
  end

  def preview_hash_switch(system_name)
    case system_name
    when 'title'
      ['This is the Resource title']
    when 'rights_statement'
      ['This is a rights statement']
    when 'publisher'
      ['The Publishing Entity']
    when 'source'
      ['Source information']
    when 'agent'
      ["Someone's Name"]
    when 'date'
      ['1975-08-02']
    when 'coverage'
      ['City, Country']
    when 'type'
      ['Audio']
    when 'language'
      ['en']
    when 'description'
      ['Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam elit risus, faucibus vulputate sagittis ac, ornare nec urna.']
    when 'format'
      ['Videocassette']
    when 'identifier'
      ['ID556843']
    when 'relation'
      ['Part of X']
    when 'subject'
      ['Lorem, ipsum, dolor, si,t amet, consectetur, adipiscing, elit']
    when 'Keyword'
      ['Mauris, variu,s laoreet, mauris, nam, lacinia, egests, mi, vel, sodales, nunc, proin, nisi, ipsum, blandit, sit, amet, est, at, vehicula,
     vulputate, purus, pellentesque, at, velit, sapien, morbi, non, dignissim, massa, a, aliquet, eros']
    when 'duration'
      ['HH:MM:SS']
    when 'preferred_citation'
      ['This is how you should cite this resource.']
    else
      ['This is some example text for your custom field.']
    end
  end
end
