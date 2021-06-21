# ResourcesListingDatatable
class ResourcesListingDatatable < ApplicationDatatable
  delegate :time_to_duration, :html_safe, :strip_tags, :truncate, :check_valid_array, :edit_collection_collection_resource_path, :collection_collection_resource_path,
           :bulk_resource_list_collections_path, :collection_resource_path, :current_organization, :boolean_value, :can?, to: :@view

  def initialize(view, caller, called_from = '', additional_data = {}, resource_fields = {})
    @view = view
    @caller = caller
    @called_from = called_from
    @resource_fields = resource_fields
    return if additional_data.blank?
    @external_id = additional_data[:external]
    @collection_id = additional_data[:collection_id]
  end

  def as_json(_options = {})
    {
      recordsTotal: count,
      recordsFiltered: total_entries,
      data: data
    }
  end

  private

  def sort_column
    if @called_from == 'permission_group' || @called_from == 'archiveSpacePreview'
      columns_list = []
      @resource_fields.each_with_index do |(system_name, single_collection_field), _index|
        field_settings = Aviary::FieldManagement::FieldManager.new(single_collection_field, system_name)
        if field_settings.should_display_on_resource_table && %w[id_ss title_ss access_ss description_identifier_sms description_date_sms].include?(field_settings.solr_display_column_name)
          columns_list << single_collection_field['solr_display_column'] if single_collection_field['solr_display_column'].to_s.to_boolean?
        end
      end
    else
      columns_list = columns
    end
    column = params[:order]['0'][:column].to_i
    columns_list[column]
  end

  def data
    resources.first.map do |resource|
      [].tap do |column|
        if %w[permission_group playlist_add_resource archiveSpacePreview].include?(@called_from)
          if @called_from == 'archiveSpacePreview'
            column << "<input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                    data-url='#{bulk_resource_list_collections_path(collection_id: resource['collection_id_is'], collection_resource_id: resource['id_is'])}' data-id='#{resource['id_is']}' />"
          end

          @resource_fields.each_with_index do |(system_name, single_collection_field), _index|
            field_settings = Aviary::FieldManagement::FieldManager.new(single_collection_field, system_name)
            if %w[id_ss title_ss access_ss description_identifier_sms description_date_sms].include?(field_settings.solr_display_column_name)
              column << manage(field_settings.solr_display_column_name, resource) if field_settings.should_display_on_resource_table
            end
          end
        else
          column << "<input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                  data-url='#{bulk_resource_list_collections_path(collection_id: resource['collection_id_is'], collection_resource_id: resource['id_is'])}' data-id='#{resource['id_is']}' />"
          if @resource_fields.present?
            @resource_fields.each_with_index do |(system_name, single_collection_field), _index|
              field_settings = Aviary::FieldManagement::FieldManager.new(single_collection_field, system_name)
              global_status = field_settings.should_display_on_detail_page
              if field_settings.field_configuration.present? && field_settings.field_configuration['special_purpose'].present? && boolean_value(field_settings.field_configuration['special_purpose'])
                global_status = true
              end
              next unless global_status

              column << manage(field_settings.solr_display_column_name, resource) if field_settings.should_display_on_resource_table
            end
          end
        end
        links = if %w[permission_group playlist_add_resource].include?(@called_from)
                  description_identifier_sms = resource['description_identifier_sms'].present? ? truncate(strip_tags(resource['description_identifier_sms'].join(', ')).gsub('::', ' ')) : 'none'
                  description_date_sms = resource['description_date_sms'].present? ? truncate(strip_tags(resource['description_date_sms'].join(', ')).gsub('::', ' ')) : 'none'
                  access_ss = resource['access_ss'].present? ? resource['access_ss'].titleize : 'none'
                  "<a href='javascript:void(0)' data-label='#{strip_tags(resource['title_ss'].to_s.delete('"'))} (#{resource['id_is']})'
                          data-value='#{strip_tags(resource['title_ss'].to_s.delete('"'))}' data-description_identifier='#{description_identifier_sms}' data-description_date='#{description_date_sms}'
                          data-access='#{access_ss}' data-id='#{resource['id_is']}' class='btn-sm btn-success add_to_resource_group'>Add</a>"
                else
                  links_set = '<a href="' + collection_collection_resource_path(resource['collection_id_is'], resource['id_is']) +
                              '"class="btn-sm btn-default">View</a>&nbsp;&nbsp;'
                  links_set += '<a href="' + edit_collection_collection_resource_path(collection_id: resource['collection_id_is'], id: resource['id_is']) +
                               '"class="btn-sm btn-success">Edit</a>&nbsp;&nbsp;'
                  if CollectionResource.where(id: resource['id_is']).present?
                    if can? :destroy, CollectionResource.find(resource['id_is'])
                      links_set += "<a href='javascript://' data-name='#{strip_tags(resource['title_ss'].to_s)}' data-url='#{collection_resource_path(resource['id_is'])}' class='btn-sm btn-danger resource_delete' >Delete</a>"
                    end
                  end
                  links_set
                end
        column << links
      end
    end
  end

  def manage(system_name, resource)
    if system_name == 'description_duration_ss'
      resource[system_name].present? ? time_to_duration(resource[system_name]) : '00:00:00'
    elsif system_name == 'collection_title'
      resources.third[resource['collection_id_is'].to_s]
    elsif system_name == 'updated_at_ss'
      resource[system_name].to_date
    elsif system_name == 'access_ss'
      resource[system_name].present? ? resource[system_name].titleize : resource[system_name]
    else
      check_valid_array(resource[system_name], system_name)
    end
  end

  def count
    resources.second
  end

  def total_entries
    resources.second
  end

  def resources
    @resources ||= fetch_resources
  end

  def fetch_resources
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    table_of_caller = ''
    if @caller.is_a?(Collection)
      table_of_caller = 'collection_id_is'
    elsif @caller.is_a?(Organization)
      table_of_caller = 'organization_id_is'
    end
    extra_conditions = []
    if @collection_id.present?
      extra_conditions << "collection_id_is:#{@collection_id}"
    end
    if @external_id.present?
      extra_conditions << '+external_resource_id_ss:[* TO *]'
    end
    CollectionResource.fetch_resources(page, per_page, sort_column, sort_direction, params, "#{table_of_caller}:#{@caller.id}", resource_fields: @resource_fields, export: false, current_organization: current_organization,
                                                                                                                                called_from: @called_from, extra_conditions: extra_conditions)
  end

  def columns
    columns_allowed = []
    columns_allowed = ['id_is'] if @called_from != 'permission_group'
    if @resource_fields.present?
      @resource_fields.each_with_index do |(_system_name, single_collection_field), _index|
        global_status = single_collection_field['description_display'].to_s.to_boolean?
        field_configuration = single_collection_field['field_configuration']
        global_status = true if field_configuration.present? && field_configuration['special_purpose'].present? && boolean_value(field_configuration['special_purpose']) && field_configuration['visible_at'].include?('resource_search')
        columns_allowed << single_collection_field['solr_display_column'] if single_collection_field['resource_table_display'].to_s.to_boolean? && global_status
      end
    end
    columns_allowed
  end
end
