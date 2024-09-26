# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ResourceFilesExportCsv
  class ResourceFilesExportCsv
    include CollectionResourceFileHelper
    include ApplicationHelper

    delegate :url_helpers, to: 'Rails.application.routes'
    def process_resource(limit_resource_ids, resource_list_params, current_organization, base_url)
      data = CollectionResourceFile.fetch_file_list(0, 0, 'id_is', 'desc', resource_list_params, limit_resource_ids, export: true, current_organization: current_organization)
      header = JSON.parse(current_organization.resource_file_display_column)['columns_status'].map { |_, a| CollectionResourceFile.fields_values[a['value']] if a['status'] == 'true' }.compact
      columns = JSON.parse(current_organization.resource_file_display_column)['columns_status'].map { |_, a| a['value'] if a['status'] == 'true' }.compact
      csv_rows = []

      csv_rows << header
      data.first.each do |resource|
        collection_resource = CollectionResource.find(resource['collection_resource_id_ss'])
        col_data = []
        columns.each do |value|
          next if value.blank?
          col_data << if value == 'resource_file_file_size_ss'
                        resource[value].present? ? ApplicationController.helpers.number_to_human_size(resource[value]) : ''
                      elsif %w[created_at_ds updated_at_ds].include?(value)
                        resource[value].present? ? resource[value].to_date.strftime('%m-%d-%Y') : ''
                      elsif value == 'access_ss'
                        resource[value].titleize
                      elsif value == 'embed_code_texts'
                        resource[value].present? ? resource[value].join(';') : ''
                      elsif value == 'embed_code_type_ss'
                        resource[value].present? ? ApplicationHelper.get_embed_content_type(resource[value]) : ApplicationHelper.get_embed_content_type(0)
                      elsif value == 'resource_file_content_type_ss'
                        resource[value].present? ? resource[value] : ''
                      elsif value == 'duration_ss'
                        resource[value].present? ? ApplicationController.helpers.time_to_duration(resource[value]) : '00:00:00'
                      elsif value == 'thumbnail_ss'
                        '<img src=' + resource[value] + ' width= "50">'
                      elsif value == 'aviary_url_path_ss'
                        base_url + "/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}"
                      elsif value == 'aviary_embed_code_ss'
                        base_url + "/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}?embed=true"
                      elsif value == 'aviary_purl_ss'
                        base_url + "/r/#{collection_resource.noid}"
                      elsif value == 'media_embed_url_ss'
                        "#{base_url}/embed/media/#{resource['id_is']}"
                      elsif value == 'player_embed_html_ss'
                        "<iframe src='#{base_url}/embed/media/#{resource['id_is']}' ></iframe>"
                      elsif value == 'resource_detail_embed_html_ss'
                        link = "#{base_url}/collections/#{collection_resource.collection.id}/collection_resources/#{resource['collection_resource_id_ss']}/file/#{resource['id_is']}?embed=true"
                        "<iframe src='#{link}'></iframe>"
                      else
                        resource[value].present? ? resource[value] : ''
                      end
        end
        csv_rows << col_data
      end
      file_name = "#{current_organization.name.delete(' ')}_media_#{Date.today}_#{Time.now.to_i}.csv"
      file_data_org = Rails.root.join('public', file_name)
      CSV.open(file_data_org, 'w') do |writer|
        csv_rows.each do |c|
          writer << c
        end
      end
      begin
        jobs = JobsDetail.new(organization: current_organization, associated_file: File.open(file_data_org), status: 1)
        jobs.save
      rescue StandardError => ex
        Rails.logger.error ex
        jobs = false
      end
      FileManager.new.delete_file(file_data_org)
      jobs
    rescue StandardError => ex
      Rails.logger.error ex
      false
    end
  end
end
