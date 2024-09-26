# MediaListingDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::MediaListingDatatable < Datatables::ApplicationDatatable
  delegate :time_to_duration, :number_to_human_size, :strip_tags, :check_valid_array,
           :options_for_select, :select_tag, :content_tag, :noid_url, :embeded_url, :collection_resource_url,
           :embed_file_url, :current_organization, :bulk_resource_list_collections_path,
           :user_change_org_status_path, :collection_collection_resource_add_resource_file_path,
           :user_remove_user_path, :collection_collection_resource_details_path,
           :collection_collection_resource_details_url, :can?, to: :@view

  def initialize(view, caller, called_from = '', additional_data = {}, media_fields = {})
    @view = view
    @caller = caller
    @called_from = called_from
    @media_fields = media_fields
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
    columns_allowed = ['id_is']
    if current_organization.try(:resource_file_display_column).present?
      resource_display_column_list = JSON.parse(current_organization.resource_file_display_column)['columns_status']
                                         .collect { |_k, v| v }
      resource_display_column_list.each { |val| columns_allowed << val['value'] if val['status'].to_s.to_boolean? }
    end

    columns_allowed.try(:[], params[:order].try(:[], '0').try(:[], :column).try(:to_i)).to_s
  end

  def data
    resources.first.map do |resource|
      collection_resource = CollectionResource.find_by(id: resource['collection_resource_id_ss'])
      if collection_resource.present?
        [].tap do |column|
          if %w[permission_group].include?(@called_from)
            resource_table_column_detail = CollectionResourceFile.permission_group_columns.to_json
            JSON.parse(resource_table_column_detail)['columns_status'].each_value do |value|
              column << manage(value, resource) if !value['status'].blank? && value['status'] == 'true'
            end
          else
            column << %(
                <label><span class="sr-only">Resource media file with ID #{resource['id_is']} titled #{resource['file_display_name_ss']}</span>
                  <input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                    data-url='#{bulk_resource_list_collections_path}' data-id='#{resource['id_is']}' data-uploaded='#{resource['resource_file_content_type_ss'].present?}' />
                </label>
              )
            common_classes = "class='btn btn-sm btn-default copy-link' data-clipboard-action='copy' data-original-title='' title='' "
            if resources.fourth.present? && !resources.fourth.resource_file_display_column.blank? && !JSON.parse(resources.fourth.resource_file_display_column)['columns_status'].blank?
              JSON.parse(resources.fourth.resource_file_display_column)['columns_status'].each_value do |value|
                if !value['status'].blank? && value['status'] == 'true' && CollectionResourceFile.media_file_field_label(value['value'], current_organization)
                  column << case value['value']
                            when 'collection_resource_title_ss'
                              resources.third[resource['collection_resource_id_ss'].to_s]
                            when 'resource_file_file_size_ss'
                              resource[value['value']].present? ? number_to_human_size(resource[value['value']]) : ''
                            when 'created_at_ds', 'updated_at_ds'
                              resource[value['value']].present? ? CollectionResourceFile.date_time_format(resource[value['value']]) : ''
                            when 'access_ss'
                              resource[value['value']].titleize
                            when 'resource_file_content_type_ss'
                              resource[value['value']].present? ? resource[value['value']] : ''
                            when 'thumbnail_ss'
                              "<img src=#{resource[value['value']]} height='20'>"
                            when 'aviary_url_path_ss'
                              "<a href=#{collection_collection_resource_details_path(collection_resource.collection.id, collection_resource.id, resource['id_is'])} class='btn-sm btn-default'>File URL</a>"
                            when 'aviary_purl_ss'
                              subdomain_handler = Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization)
                              "<a href=#{noid_url(noid: collection_resource.noid, host: subdomain_handler)} class='btn-sm btn-default'>Aviary PURL</a>"
                            when 'media_embed_url_ss'
                              "<a href=#{embeded_url(embed_file_url(collection_resource), 'embed', resource['id_is'])} class='btn-sm btn-default'>Embed URL</a>"
                            when 'player_embed_html_ss'
                              iframe = "<iframe src='#{embeded_url(embed_file_url(collection_resource), 'embed', resource['id_is'])}' height='400' width='600'></iframe>"
                              button = "<button #{common_classes} data-clipboard-target='#player_embed_html_#{resource['id_is']}' >Click to Copy </button> "
                              "#{button}<textarea class='hide-copy-textarea' id='player_embed_html_#{resource['id_is']}'>#{iframe}</textarea>"
                            when 'resource_detail_embed_html_ss'
                              iframe = "<iframe src='#{collection_collection_resource_details_url(collection_resource.collection.id, collection_resource.id, resource['id_is']) + '?embed=true'}' height='400' width='1200' style='width: 100%;'></iframe>"
                              button = "<button #{common_classes} data-clipboard-target='#resource_detail_embed_html_#{resource['id_is']}'  >Click to Copy</button>"
                              " #{button} <textarea class='hide-copy-textarea' id='resource_detail_embed_html_#{resource['id_is']}'>#{iframe}</textarea>"
                            when 'embed_code_texts'
                              if resource[value['value']]
                                embed_code = check_valid_array(resource[value['value']], value['value'])
                                button = "<button #{common_classes} data-clipboard-target='#embed_code_texts_#{resource['id_is']}'  >Click to Copy</button>"
                                " #{button} <textarea class='hide-copy-textarea' id='embed_code_texts_#{resource['id_is']}'>#{embed_code}</textarea>"
                              else
                                'none'
                              end
                            when 'duration_ss'
                              resource[value['value']].present? ? time_to_duration(resource[value['value']]) : '00:00:00'
                            when /(description_|custom_field_values_)/
                              check_valid_array(resource[value['value']], value['value'])
                            when 'collection_title_text'
                              collection_resource.collection.title
                            when 'is_cc_on_ss', 'is_downloadable_ss'
                              resource[value['value']] ? 'Yes' : 'No'
                            else
                              resource[value['value']].present? ? resource[value['value']] : 'none'
                            end
                end
              end
            end
          end

          links = if %w[permission_group playlist_add_resource].include?(@called_from)
                    access_ss = resource['access_ss'].present? ? resource['access_ss'].titleize : 'none'
                    "<a href='javascript:void(0)' data-label='#{strip_tags(resource['file_display_name_ss'].to_s.delete('"'))} (#{resource['id_is']})'
                              data-value='#{strip_tags(resource['file_display_name_ss'].to_s.delete('"'))}' data-resource_title='#{strip_tags(resource['collection_resource_title_ss'].to_s.delete('"'))}'
                              data-file_type='#{resource['resource_file_content_type_ss']}'
                              data-access='#{access_ss}' data-id='#{resource['id_is']}' data-resource_id='#{resource['collection_resource_id_ss']}' class='btn-sm btn-success add_to_mediafiles_group'>Add</a>"
                  else
                    begin
                      links_set = '<a href="' + collection_collection_resource_details_path(collection_resource.collection.id, resource['collection_resource_id_ss'], resource['id_is']) +
                                  '"class="btn-sm btn-default hidden_focus_btn" data-id="collection_resource_view_' + resource['id_is'].to_s + '">View</a>&nbsp;&nbsp;'
                      links_set += '<a href="' + collection_collection_resource_add_resource_file_path(collection_resource.collection.id, resource['collection_resource_id_ss']) +
                                   '"class="btn-sm btn-success hidden_focus_btn" data-id="collection_resource_edit_' + resource['id_is'].to_s + '">Edit</a>&nbsp;&nbsp;'
                    rescue StandardError => e
                      links_set = ''
                      puts e.backtrace.join("\n")
                    end
                    links_set
                  end

          column << links
        end
      end
    end
  end

  def manage(value, resource)
    if value['value'] == 'access_ss'
      resource[value['value']].present? ? resource[value['value']].titleize : resource[value['value']]
    elsif value['value'] == 'collection_resource_title_ss'
      resources.third[resource['collection_resource_id_ss'].to_s]
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
    CollectionResourceFile.fetch_file_list(page, per_page, sort_column, sort_direction, params,
                                           "#{table_of_caller}:#{@caller.id}", media_fields: @media_fields,
                                                                               export: false,
                                                                               current_organization: current_organization,
                                                                               called_from: @called_from,
                                                                               extra_conditions: extra_conditions)
  end

  def columns(resource_file_search_column = false)
    columns_allowed = ['id_is']
    if resource_file_search_column.present?
      resource_file_search_column.each_value do |value|
        if !value['status'].blank? && value['status'] == 'true'
          columns_allowed << value['value']
        end
      end
    end
    columns_allowed
  end
end
