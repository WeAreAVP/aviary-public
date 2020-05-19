# PreviewScript
class PreviewScript
  def initialize(collection, params = nil)
    @params = params
    @collection = collection
  end

  def data_hash(resource, collection_fields = nil)
    title = resource.present? ? resource.title : 'This is the Resource Title'

    data_hash = { 'resource_title' => title, 'collection_title' => @collection.title, 'organization_title' => @collection.organization.name }

    resource_fields = collection_fields['CollectionResource']
    if resource.present?
      resource_fields = resource.all_fields['CollectionResource']
    end

    tombstone_hash = {}

    resource_fields.each_with_index do |single_field, index|
      value_array = []
      is_tombstone = single_field['settings'][:is_tombstone]

      fields_value = if resource.present?
                       values = single_field['values']
                       values.present? ? values : preview_hash_switch(single_field['field'].system_name)
                     else
                       preview_hash_switch(single_field['field'].system_name)
                     end

      fields_value.each do |field|
        value_array << if field.is_a?(String)
                         { 'value' => field }
                       else
                         { 'is_vocabulary' => single_field['field'].is_vocabulary, 'vocabulary_value' => field['vocab_value'],
                           'value' => field['value'].present? ? field['value'] : preview_hash_switch(single_field['field'].system_name).first, 'token' => single_field['field'].column_type, token_value: field['value'].to_s.split(',') }
                       end
      end
      tombstone_hash[(index + 1)] = { single_field['field'].system_name => [{ 'is_tombstone' => is_tombstone, 'is_visible' => single_field['settings'][:is_visible] }, value_array] }
      data_hash['fields'] = tombstone_hash
    end
    data_hash
  end

  def update_data_hash(data_hash)
    total = data_hash['fields'].count
    if @params['new_custom_value']['new_custom_field'].present?
      data_hash['fields'][total + 1] = { @params['new_custom_value']['new_custom_field'] => [{ 'is_tombstone' => false, 'is_visible' => true },
                                                                                             [{ 'value' => preview_hash_switch(@params['new_custom_value']['new_custom_field']).first }]] }
    end

    data_hash['collection_title'] = @params['collection_title']
    data_hash['fields'].each do |_k, v|
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

    if @params['sort_order']['sort_data'].present?
      @params['sort_order']['sort_data'].each do |k, v|
        (1..total).each do |i|
          if data_hash['fields'][i].present? && data_hash['fields'][i].first.first == k
            value = data_hash['fields'][i]
            abc = data_hash['fields'][v.to_i]
            data_hash['fields'][v.to_i] = value
            data_hash['fields'].merge!(i => abc)
          end
        end
      end
    end

    data_hash
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
