# helpers/organization_fields_helper.rb
#
# Author::    Usman Javaid  (mailto:usmanjzcn@gmail.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module OrganizationFieldsHelper
  def field_settings(organization, value_for, *keys)
    org_field_manager.organization_field_settings(organization, value_for, *keys)
  end

  def part_of_collections_hash
    part_of_collections = {}
    return part_of_collections unless current_organization.collections.present?

    current_organization.collections.each do |single_collection|
      single_collection_value = single_collection.collection_fields_and_value

      next unless single_collection_value.present? && single_collection_value.resource_fields.present?

      single_collection_value.resource_fields.each_key do |system_name, _single_collection_field|
        part_of_collections = OrganizationFieldPresenter.part_of_collection(
          current_organization, part_of_collections, system_name, single_collection
        )
      end
    end

    part_of_collections
  end

  def new_field_hash
    { label: '', system_name: '', field_type: '', is_required: false, is_public: false, is_default: false,
      is_vocabulary: false, vocabulary: [], help_text: '', is_repeatable: false, is_internal_only: false,
      field_configuration: {}, field_level: 'collection', sort_order: 0, display: true }
  end

  def edit_field_hash(field_type)
    field_information = field_settings(current_organization, nil, field_type)
    field_information[params['system_name']]
  end

  def generate_collections_list
    collections_list = {}

    current_organization.collections.each do |single_collection|
      single_collection_value = single_collection.collection_fields_and_value

      if params[:action_type] == '1' && single_collection_value.resource_fields[params['field']].present? ||
         (params[:action_type] == '0' && (single_collection_value.blank? ||
          single_collection_value.resource_fields[params['field']].blank?))

        @collections_list[single_collection.id] = single_collection.title
      end
    end

    collections_list
  end

  def handle_assign_field
    collection = params[:collection_ids].present? ? Collection.where(id: params[:collection_ids]) : nil

    return unless collection.present?

    case params[:action_type]
    when '0'
      update_information = { 'system_name' => params['field'], 'status' => true, 'tombstone' => false,
                             'sort_order' => 0 }
      @collection_field_manager.update_field_settings_collection(update_information, collection, 'resource_fields')
    when '1'
      collection.each do |single_collection|
        @collection_field_manager.delete_field(single_collection, 'resource_fields', params['field'])
      end
    end
  end

  def update_sort_or_ris
    organization = if params['config_type'].present? && params['flock_id'].present?
                     Organization.find(params['flock_id'])
                   else
                     current_organization
                   end

    if params['info'].present?
      org_field_manager.update_field_settings(field_settings(organization, nil, params['type']),
                                              JSON.parse(params['info'].to_json), organization, params['type'])
    end

    return unless params['fixed_column'].present?

    current_organization.organization_field.update(fixed_column: params['fixed_column'])
  end

  def update_sort_collection(fields_type)
    collection = current_organization.collections.find_by_id(params['collection_id'])
    @collection_field_manager.update_field_settings(JSON.parse(params['info'].to_json), collection, fields_type)
    collection.solr_index
  end

  def add_field_to_select_collection
    collection = current_organization.collections.find_by_id(params['collection_id'])
    @collection_field_manager.update_field_settings_collection(update_information_hash, collection, 'resource_fields')
  end

  def update_information_hash
    { 'system_name' => params['field'],
      'status' => params['status'].present? ? params['status'].to_s.to_boolean? : true,
      'tombstone' => params['tombstone'].present? ? params['tombstone'].to_s.to_boolean? : false,
      'sort_order' => params['sort_order'].present? ? params['sort_order'].to_i : 0 }
  end

  def update_index_fields_vocabulary
    index_fields_settings = current_organization.organization_field.index_fields

    if params[:update_type] == '1'
      index_fields_settings[params[:field]]['vocabulary'].append(params['vocabulary'].split(',').map(&:strip)).flatten
    else
      index_fields_settings[params[:field]]['vocabulary'] = params['vocabulary'].split(',').map(&:strip)
    end

    current_organization.organization_field.update(index_fields: index_fields_settings)
  end

  def edit_vocabulary
    list_type = params['list_type']
    params['vocabulary'] = str_to_array(params['vocabulary'])
    field_values = org_field_manager.organization_field_settings(current_organization, nil, params['type'])

    update_information = if list_type == 'dropdown_options'
                           update_dropdown_options(field_values)
                         else
                           update_vocabulary(field_values)
                         end

    org_field_manager.update_field_settings(field_values, update_information, current_organization, params['type'])
  end

  def update_dropdown_options(field_values)
    current_vocabulary = case params['update_type']
                         when 'reset_to_default'
                           Rails.configuration.default_fields['fields']['resource'][params['field']]['vocabulary']
                         when '1'
                           field_values[params['field']]['field_configuration']['dropdown_options'].append(
                             params['vocabulary']
                           ).flatten
                         else
                           params['vocabulary']
                         end

    { '0' => { 'system_name' => params['field'],
               'field_configuration' => { 'dropdown_options' => current_vocabulary.try(:uniq) } } }
  end

  def update_vocabulary(field_values)
    current_vocabulary = case params['update_type']
                         when 'reset_to_default'
                           Rails.configuration.default_fields['fields']['resource'][params['field']]['vocabulary']
                         when '1'
                           field_values[params['field']]['vocabulary'].append(params['vocabulary']).flatten
                         else
                           params['vocabulary']
                         end

    { '0' => { 'system_name' => params['field'], 'vocabulary' => current_vocabulary.try(:uniq),
               'is_vocabulary' => current_vocabulary.present? } }
  end

  def create_update_organization_fields
    vocabulary_and_dropdown_options_to_array

    message, type = if params['meta_field_id'].blank?
                      create_field(params['custom_fields'])
                    else
                      update_field(params['custom_fields'])
                    end

    [message, type]
  end

  def vocabulary_and_dropdown_options_to_array
    if params['custom_fields']['vocabulary'].present?
      params['custom_fields']['vocabulary'] = str_to_array(params['custom_fields']['vocabulary'])
    end

    return unless params['custom_fields']['dropdown_options'].present?

    params['custom_fields']['dropdown_options'] = str_to_array(params['custom_fields']['dropdown_options'])
  end

  def create_field(field_configs)
    field_type = params['type'] || 'resource_fields'

    all_fields = current_organization.organization_field[field_type]
    system_name = field_configs['label'].parameterize.underscore
    all_fields[system_name] = if field_type == 'collection_fields'
                                collection_field_hash(system_name, field_configs)
                              else
                                resource_field_hash(system_name, field_configs)
                              end

    if Rails.configuration.default_fields['fields'][field_type.sub('_fields', '')].keys.include?(system_name)
      type = :danger
      message = "\"#{field_configs['label']}\" is reserved field name. Please use a different field name."
    else
      current_organization.organization_field.update(field_type.to_sym => all_fields)
    end

    [message || 'Information updated successfully', type || :notice]
  end

  def collection_field_hash(system_name, field_configs)
    {
      label: field_configs['label'],
      default_name: field_configs['label'],
      system_name: system_name,
      field_type: field_configs['field_type'],
      is_required: field_configs['is_required'].to_s.to_boolean?,
      is_public: field_configs['is_public'].to_s.to_boolean?,
      is_default: false,
      is_vocabulary: field_configs['vocabulary'].present?,
      tombstone: false,
      vocabulary: field_configs.try(:[], 'vocabulary') || [],
      help_text: field_configs['help_text'],
      is_repeatable: field_configs['is_repeatable'].to_s.to_boolean?,
      field_configuration: { 'dropdown_options' => field_configs.try(:[], 'dropdown_options') || [] },
      field_level: 'collection',
      sort_order: current_organization.organization_field.resource_fields.keys.count.to_i + 1,
      display: true
    }
  end

  def resource_field_hash(system_name, field_configs)
    {
      'label' => field_configs['label'],
      'help_text' => field_configs['help_text'],
      'is_public' => field_configs['is_public'].to_s.to_boolean?,
      'field_type' => field_configs['field_type'],
      'is_default' => false,
      'is_repeatable' => field_configs['is_repeatable'].to_s.to_boolean?,
      'is_internal_only' => field_configs['is_internal_only']&.to_s&.to_boolean?,
      'field_level' => 'resource',
      'is_required' => field_configs['is_required'].to_s.to_boolean?,
      'system_name' => system_name,
      'is_vocabulary' => field_configs['vocabulary'].present?,
      'vocabulary' => field_configs['vocabulary'].presence || [],
      'field_configuration' => { 'dropdown_options' => field_configs['dropdown_options'].presence || [] },
      'sort_order' => current_organization.organization_field.resource_fields.keys.count.to_i + 1,
      'description_display' => true,
      'resource_table_display' => false,
      'resource_table_search' => false,
      'solr_search_column' => Aviary::SolrIndexer.define_custom_field_system_name(system_name) + '_texts',
      'resource_table_sort_order' => current_organization.organization_field.resource_fields.keys.count.to_i + 1,
      'search_sort_order' => current_organization.organization_field.resource_fields.keys.count.to_i + 1,
      'search_display' => false,
      'solr_display_column' => Aviary::SolrIndexer.define_custom_field_system_name(system_name,
                                                                                   field_configs['field_type'], true)
    }
  end

  def update_field(field_configs)
    field_values = field_settings(current_organization, nil, params['type'].presence || 'resource_fields')

    field_configs.delete('is_custom')
    field_configs.delete('vocabulary')
    field_configs.delete('is_vocabulary')
    field_configs.delete('column_type')
    field_configs.delete('dropdown_options')

    field_configs['field_type'] = field_configs['column_type'].presence
    field_configs['is_public'] = field_configs['is_public'].to_s.to_boolean?
    field_configs['is_repeatable'] = field_configs['is_repeatable'].to_s.to_boolean?
    field_configs['is_required'] = field_configs['is_required'].to_s.to_boolean?
    unless params['type'] == 'collection_fields'
      field_configs['is_internal_only'] = field_configs['is_internal_only'].to_s.to_boolean?
    end

    org_field_manager.update_field_settings(field_values, { '0' => field_configs }, current_organization,
                                            params['type'].presence || 'resource_fields')

    ['Information updated successfully', :notice] # [message, type]
  end

  def org_field_manager
    Aviary::FieldManagement::OrganizationFieldManager.new
  end
end
