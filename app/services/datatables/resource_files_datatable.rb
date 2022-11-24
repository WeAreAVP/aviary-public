# UsersDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ResourceFilesDatatable < ApplicationDatatable
  delegate :time_to_duration, :number_to_human_size, :options_for_select, :select_tag, :content_tag, :noid_url, :embeded_url, :collection_resource_url, :embed_file_url,
           :current_organization, :bulk_resource_list_collections_path, :user_change_org_status_path, :collection_collection_resource_add_resource_file_path,
           :user_remove_user_path, :collection_collection_resource_details_path, :collection_collection_resource_details_url, :check_valid_array, :can?, to: :@view

  def initialize(view, caller)
    @view = view
    @caller = caller
    @current_organization = current_organization
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
    columns(JSON.parse(@current_organization.resource_file_display_column)['columns_status'])[params[:order]['0'][:column].to_i]
  end

  def data
    resources.first.map do |resource|
      [].tap do |column|
        column << "<input type='checkbox' class='resources_selections resources_selections-#{resource['id_is']}'
                  data-url='#{bulk_resource_list_collections_path}' data-id='#{resource['id_is']}' />"
        common_classes = "class='btn btn-sm btn-default copy-link' data-clipboard-action='copy' data-original-title='' title='' "
        collection_resource = CollectionResource.find(resource['collection_resource_id_ss'])
        if resources.fourth.present? && !resources.fourth.resource_file_display_column.blank? && !JSON.parse(resources.fourth.resource_file_display_column)['columns_status'].blank?
          JSON.parse(resources.fourth.resource_file_display_column)['columns_status'].each do |_, value|
            if !value['status'].blank? && value['status'] == 'true'

              column << if value['status'] == 'true'
                          begin
                            if value['value'] == 'resource_file_file_size_ss'
                              resource[value['value']].present? ? number_to_human_size(resource[value['value']]) : ''
                            elsif %w[created_at_ds updated_at_ds].include?(value['value'])
                              resource[value['value']].present? ? CollectionResourceFile.date_time_format(resource[value['value']]) : ''
                            elsif value['value'] == 'access_ss'
                              resource[value['value']].titleize
                            elsif value['value'] == 'resource_file_content_type_ss'
                              resource[value['value']].present? ? resource[value['value']] : ''
                            elsif value['value'] == 'thumbnail_ss'
                              '<img src=' + resource[value['value']] + ' height= "20">'
                            elsif value['value'] == 'aviary_url_path_ss'
                              '<a href="' + collection_collection_resource_details_path(collection_resource.collection.id,
                                                                                        collection_resource.id, resource['id_is']) + '"class="btn-sm btn-default">File URL</a>'
                            elsif value['value'] == 'aviary_purl_ss'
                              subdomain_handler = Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization)
                              '<a href="' + noid_url(noid: collection_resource.noid, host: subdomain_handler) + '"class="btn-sm btn-default">Aviary PURL</a>'

                            elsif value['value'] == 'media_embed_url_ss'
                              '<a href="' + embeded_url(embed_file_url(collection_resource), 'embed', resource['id_is']) + '"class="btn-sm btn-default">Embed URL</a>'
                            elsif value['value'] == 'player_embed_html_ss'
                              iframe = "<iframe src='#{embeded_url(embed_file_url(collection_resource), 'embed', resource['id_is'])}' height='400' width='600'></iframe>"
                              button = "<button #{common_classes} data-clipboard-target='#player_embed_html_#{resource['id_is']}' >Click to Copy </button> "
                              "#{button}<textarea class='hide-copy-textarea' id='player_embed_html_#{resource['id_is']}'>#{iframe}</textarea>"
                            elsif value['value'] == 'resource_detail_embed_html_ss'
                              iframe = "<iframe src='#{collection_collection_resource_details_url(collection_resource.collection.id, collection_resource.id, resource['id_is']) + '?embed=true'}'
height='400' width='1200' style='width: 100%;'></iframe>"

                              button = "<button #{common_classes} data-clipboard-target='#resource_detail_embed_html_#{resource['id_is']}'  >Click to Copy</button>"
                              " #{button} <textarea class='hide-copy-textarea' id='resource_detail_embed_html_#{resource['id_is']}'>#{iframe}</textarea>"
                            elsif value['value'] == 'embed_code_texts'
                              if resource[value['value']]
                                embed_code = check_valid_array(resource[value['value']], value['value'])
                                button = "<button #{common_classes} data-clipboard-target='#embed_code_texts_#{resource['id_is']}'  >Click to Copy</button>"
                                " #{button} <textarea class='hide-copy-textarea' id='embed_code_texts_#{resource['id_is']}'>#{embed_code}</textarea>"
                              else
                                'none'
                              end
                            elsif value['value'] == 'duration_ss'
                              resource[value['value']].present? ? time_to_duration(resource[value['value']]) : '00:00:00'
                            elsif value['value'] == 'collection_title_text'
                              collection_resource.collection.title
                            elsif value['value'] == 'is_cc_on_ss'
                              resource[value['value']] ? 'Yes' : 'No'
                            elsif value['value'] == 'is_downloadable_ss'
                              resource[value['value']] ? 'Yes' : 'No'
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
        links = ''
        begin
          links = '<a href="' + collection_collection_resource_details_path(collection_resource.collection.id, resource['collection_resource_id_ss'], resource['id_is']) +
                  '"class="btn-sm btn-default">View</a>&nbsp;&nbsp;'
          links += '<a href="' + collection_collection_resource_add_resource_file_path(collection_resource.collection.id, resource['collection_resource_id_ss']) +
                   '"class="btn-sm btn-success">Edit</a>&nbsp;&nbsp;'
        rescue StandardError => e
          puts e.backtrace.join("\n")
        end
        column << links
      end
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
    table_of_caller = 'organization_id_is'
    CollectionResourceFile.fetch_file_list(page, per_page, sort_column, sort_direction, params, "#{table_of_caller}:#{@caller.id}", export: false, current_organization: current_organization)
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
