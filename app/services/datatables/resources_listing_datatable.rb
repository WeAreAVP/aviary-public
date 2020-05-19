# ResourcesListingDatatable
class ResourcesListingDatatable < ApplicationDatatable
  delegate :time_to_duration, :html_safe, :strip_tags, :truncate, :edit_collection_collection_resource_path, :collection_collection_resource_path,
           :bulk_resource_list_collections_path, :collection_resource_path, :current_organization, :can?, to: :@view

  def initialize(view, caller, called_from = '')
    @view = view
    @caller = caller
    @called_from = called_from
  end

  def as_json(_options = {})
    {
      recordsTotal: count,
      recordsFiltered: total_entries,
      data: data
    }
  end

  private

  def check_valid_array(value, attribute)
    value_current = 'none'
    return value_current unless value.present?
    value_current = if value.class == Array
                      raw_values = []
                      value.each do |single_value|
                        raw_values << if single_value.include? ' :: '
                                        custom_value = single_value.split(' :: ')
                                        "#{custom_value[1]} (#{custom_value[0]})"
                                      else
                                        single_value
                                      end
                      end
                      raw_values.join(', ')
                    else
                      value
                    end
    %w(title_ss collection_title).include?(attribute) ? strip_tags(value_current.to_s).gsub('::', ' ') : truncate(strip_tags(value_current.to_s).gsub('::', ' '), length: 50)
  end

  def sort_column
    columns(current_organization.resource_table_column_detail)[params[:order]['0'][:column].to_i]
  end

  def data
    resources.first.map do |resource|
      [].tap do |column|
        if %w[permission_group playlist_add_resource].include?(@called_from)
          resource_table_column_detail = CollectionResource.permission_group_columns.to_json
          JSON.parse(resource_table_column_detail)['columns_status'].each do |_, value|
            column << manage(value, resource) if !value['status'].blank? && value['status'] == 'true'
          end
        else
          column << "<input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                  data-url='#{bulk_resource_list_collections_path(collection_id: resource['collection_id_is'], collection_resource_id: resource['id_is'])}' data-id='#{resource['id_is']}' />"
          if resources.fourth.present? && !resources.fourth.resource_table_column_detail.blank? && !JSON.parse(resources.fourth.resource_table_column_detail).blank?
            JSON.parse(resources.fourth.resource_table_column_detail)['columns_status'].each do |_, value|
              column << manage(value, resource) if !value['status'].blank? && value['status'] == 'true'
            end
          end
        end
        links = if %w[permission_group playlist_add_resource].include?(@called_from)
                  description_identifier_sms = resource['description_identifier_sms'].present? ? truncate(strip_tags(resource['description_identifier_sms'].join(', ')).gsub('::', ' ')) : 'none'
                  description_date_sms = resource['description_date_sms'].present? ? truncate(strip_tags(resource['description_date_sms'].join(', ')).gsub('::', ' ')) : 'none'
                  access_ss = resource['access_ss'].present? ? resource['access_ss'].titleize : 'none'
                  "<a href='javascript:void(0)' data-label='#{strip_tags(resource['title_ss'].delete('"'))} (#{resource['id_is']})'
                          data-value='#{strip_tags(resource['title_ss'].delete('"'))}' data-description_identifier='#{description_identifier_sms}' data-description_date='#{description_date_sms}'
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

  def manage(value, resource)
    if value['value'] == 'description_duration_ss'
      resource[value['value']].present? ? time_to_duration(resource[value['value']]) : '00:00:00'
    elsif value['value'] == 'collection_title'
      resources.third[resource['collection_id_is'].to_s]
    elsif value['value'] == 'updated_at_ss'
      resource[value['value']].to_date
    elsif value['value'] == 'access_ss'
      resource[value['value']].titleize
    else
      check_valid_array(resource[value['value']], value['value'])
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
    columns(current_organization.resource_table_column_detail).each do |term|
      search_string << "#{term} like :search"
    end
    table_of_caller = ''
    if @caller.is_a?(Collection)
      table_of_caller = 'collection_id_is'
    elsif @caller.is_a?(Organization)
      table_of_caller = 'organization_id_is'
    end
    CollectionResource.fetch_resources(page, per_page, sort_column, sort_direction, params, "#{table_of_caller}:#{@caller.id}", export: false, current_organization: current_organization, called_from: @called_from)
  end

  def columns(resource_table_column_detail = false)
    columns_allowed = []
    columns_allowed = ['id_is'] if @called_from != 'permission_group'
    if resource_table_column_detail && JSON.parse(resource_table_column_detail).present?
      JSON.parse(resource_table_column_detail)['columns_status'].each do |_, value|
        if !value['status'].blank? && value['status'] == 'true'
          columns_allowed << value['value']
        end
      end
    end
    columns_allowed
  end
end
