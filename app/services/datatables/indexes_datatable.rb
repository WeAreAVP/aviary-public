# IndexesDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class IndexesDatatable < ApplicationDatatable
  delegate :strip_tags, :check_valid_array,
           :current_organization, :bulk_resource_list_collections_path,
           :collection_collection_resource_details_path, :delete_file_index_path, :can?, to: :@view

  def initialize(view, caller, called_from = '', additional_data = {})
    @view = view
    @caller = caller
    @current_organization = current_organization
    @called_from = called_from
    return if additional_data.blank?
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
    columns(JSON.parse(@current_organization.file_index_display_column)['columns_status'])[params[:order]['0'][:column].to_i]
  end

  def data
    resources.first.map do |resource|
      [].tap do |column|
        if %w[permission_group].include?(@called_from)
          resource_table_column_detail = FileIndex.permission_group_columns.to_json
          JSON.parse(resource_table_column_detail)['columns_status'].each do |_, value|
            column << manage(value, resource) if !value['status'].blank? && value['status'] == 'true'
          end
        else
          column << %(
            <label><span class="sr-only">File index with ID #{resource['id_is']} titled #{resource['title_ss']}</span>
              <input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                data-url='#{bulk_resource_list_collections_path}' data-id='#{resource['id_is']}' />
            </label>
          )

          if resources.fourth.present? && !resources.fourth.resource_file_display_column.blank? && !JSON.parse(resources.fourth.resource_file_display_column)['columns_status'].blank?
            JSON.parse(resources.fourth.file_index_display_column)['columns_status'].each do |_, value|
              if !value['status'].blank? && value['status'] == 'true'

                column << if value['status'] == 'true'
                            begin
                              if %w[created_at_ds updated_at_ds].include?(value['value'])
                                resource[value['value']].present? ? CollectionResourceFile.date_time_format(resource[value['value']]) : ''
                              else
                                resource[value['value']].present? ? resource[value['value']] : ''
                              end
                            rescue StandardError => e
                              puts e.backtrace.join("\n")
                              ''
                            end
                          end
              end
            end
          end
        end

        links = if %w[permission_group playlist_add_resource].include?(@called_from)
                  access_ss = resource['is_public_ss']
                  "<a href='javascript:void(0)' data-label='#{strip_tags(resource['title_ss'].to_s.delete('"'))} (#{resource['id_is']})'
                          data-value='#{strip_tags(resource['title_ss'].to_s.delete('"'))}' data-resource_title='#{strip_tags(resource['collection_resource_title_ss'].to_s.delete('"'))}'
                          data-media_title='#{resource['file_display_name_ss']}'
                          data-access='#{access_ss}' data-id='#{resource['id_is']}' class='btn-sm btn-success add_to_index_group'>Add</a>"
                else
                  begin
                    data = FileIndex.find(resource['id_is'])
                    link_set = '<a href="' + collection_collection_resource_details_path(data.collection_resource_file.collection_resource.collection.id,
                                                                                         data.collection_resource_file.collection_resource.id,
                                                                                         data.collection_resource_file.id, 'index',
                                                                                         selected_index: resource['id_is']) +
                               '"class="btn-sm btn-default hidden_focus_btn" data-id="collection_resource_view_' + resource['id_is'].to_s + '">View</a>&nbsp;&nbsp;'
                    link_set += "<a href='javascript://' data-name='#{strip_tags(resource['title_ss'].to_s)}' data-url='#{delete_file_index_path(resource['id_is'])}' class='btn-sm btn-danger index_delete hidden_focus_btn' data-id='collection_resource_delete_" + resource['id_is'].to_s + "' >Delete</a>"
                    link_set
                  rescue StandardError => e
                    puts e.backtrace.join("\n")
                    'Nouman'
                  end
                end

        column << links
      end
    end
  end

  def manage(value, resource)
    check_valid_array(resource[value['value']], value['value'])
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
    table_of_caller = 'organization_id_is'
    CollectionResourceFile
    FileIndex.fetch_index_list(page, per_page, sort_column, sort_direction, params, "#{table_of_caller}:#{@caller.id}", export: false, current_organization: current_organization)
  end

  def columns(resource_file_search_column = false)
    columns_allowed = ['id_is']
    if resource_file_search_column&.present?
      resource_file_search_column.each do |_, value|
        if !value['status'].blank? && value['status'] == 'true'
          columns_allowed << value['value']
        end
      end
    end
    columns_allowed
  end
end
