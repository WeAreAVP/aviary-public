# MyresourcesController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class MyresourcesController < ApplicationController
  include ApplicationHelper
  include SearchHelper
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def update_note
    resource_list = ResourceList.find_by(user_id: current_user.id, resource_id: params['id'])
    if resource_list.present?
      unless params['myresources_edit_note'].blank?
        resource_list.note = params['myresources_edit_note']
        resource_list.save
      end
    end
    redirect_to listing_for_my_resources_url(subdomain: false), notice: 'Note updated successfully.'
  end

  def delete_note
    resource_list = ResourceList.find_by(user_id: current_user.id, resource_id: params['id'])
    if resource_list.present?
      resource_list.destroy
    end
    redirect_to listing_for_my_resources_url(subdomain: false), notice: 'Note deleted successfully.'
  end

  def get_resource_data(resource, item)
    info = ''
    if %w[description_source_sms description_date_sms description_relation_sms].include?(item)
      if resource[item].is_a?(Array)
        info = resource[item][0]
        if info.include?('::')
          info = info.split('::')[1]
        end
        if item == 'description_date_sms'
          info = Aviary::General.new.date_handler_helper(info)
          info = Time.at(info.to_i).to_datetime.strftime('%Y/%m/%d')
        end
      end
    elsif resource[item].present?
      info = if resource[item].is_a?(Array)
               if item == 'description_description_sms'
                 resource[item].join(' ')
               else
                 resource[item].join('|')
               end
             else
               resource[item]
             end
    end
    info
  end

  def get_ris_lable_data(org_field_manager_info, item, default)
    info = default
    if org_field_manager_info[item].present?
      if org_field_manager_info[item]['ris_label'].present? && !org_field_manager_info[item]['ris_label'].empty?
        info = org_field_manager_info[item]['ris_label']
      end
    end
    info
  end

  def download_myresources
    solr_search_management = SolrSearchManagement.new
    collection_resource = solr_search_management.select_query(q: '*:*', fq: ['document_type_ss:collection_resource', "id_is:(#{session['search_playlist_id'].keys.join(' OR ')})"])
    if collection_resource.present? && collection_resource['response'].present? && collection_resource['response']['docs']
      resource_list = ResourceList.where(user_id: current_user.id)
      myresource_list = {}
      resource_list.each do |resource|
        myresource_list[resource.resource_id] = {
          'id' => resource.id, 'note' => resource.note, 'updated_at' => resource.updated_at.to_datetime.strftime('%Y/%m/%d/%H:%M:%S')
        }
      end

      file_name = "myresources-#{Time.now.to_i}.ris"
      file_path = Rails.root.join('tmp').join(file_name).to_s
      file = File.new(file_path, 'w')
      collection_resource['response']['docs'].each do |resource|
        document_organization = solr_organization(resource['organization_id_is'])
        resource_url = document_detail_url(resource, document_organization)
        org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
        org_field_manager_info = org_field_manager.organization_field_settings(Organization.find(resource['organization_id_is']), nil, 'resource_fields')
        file.puts('TY  - WEB')
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'title', 'TI')}  - #{get_resource_data(resource, 'title_ss')}")
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'source', 'PB')}  - #{get_resource_data(resource, 'description_source_sms')}")
        show_empty = 1
        if resource['description_agent_sms'].present?
          resource['description_agent_sms'].each do |agent|
            agent = agent.delete(',')
            if agent.include?('::')
              temp =  agent.split('::')
              agent = "#{temp[1].split(' ').join(', ')}, #{temp[0]}"
            end
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'agent', 'AU')}  - #{agent}")
            show_empty = 0
          end
        end
        if show_empty == 1
          file.puts("#{get_ris_lable_data(org_field_manager_info, 'agent', 'AU')}  - ")
        end
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'description', 'AB')}  - #{get_resource_data(resource, 'description_description_sms')}")
        show_empty = 1
        if resource['description_keyword_sms'].present?
          resource['description_keyword_sms'].each do |keyword|
            if keyword.include?('::')
              keyword =  keyword.split('::')[1]
            end
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'keyword', 'KW')}  - #{keyword}")
            show_empty = 0
          end
        end
        if resource['description_subject_sms'].present?
          resource['description_subject_sms'].each do |subject|
            if subject.include?('::')
              subject =  subject.split('::')[1]
            end
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'keyword', 'KW')}  - #{subject}")
            show_empty = 0
          end
        end
        if show_empty == 1
          file.puts("#{get_ris_lable_data(org_field_manager_info, 'keyword', 'KW')}  - ")
        end
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'date', 'DA')}  - #{get_resource_data(resource, 'description_date_sms')}")
        dates = []
        if resource['description_date_sms'].present? && resource['description_date_sms'][0].present?
          date = resource['description_date_sms'][0]
          if date.include?('::')
            date = date.split('::')
            if date.length > 1
              date = date[1]
            end
          end
          date = Aviary::General.new.date_handler_helper(date)
          date = Time.at(date.to_i).to_datetime.strftime('%Y')
          dates << date
        end
        file.puts("PY  - #{dates.join('')}")
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'relation', 'L3')}  - #{get_resource_data(resource, 'description_relation_sms')}")
        show_empty = 1
        if resource['description_identifier_sms'].present?
          resource['description_identifier_sms'].each do |identifier|
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'identifier', 'ID')}  - #{identifier}")
            show_empty = 0
          end
        end
        if show_empty == 1
          file.puts("#{get_ris_lable_data(org_field_manager_info, 'identifier', 'ID')}  - ")
        end
        show_empty = 1
        if resource['description_language_sms'].present?
          resource['description_language_sms'].each do |language|
            if language.include?('::')
              language = language.split('::')[1]
            end
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'language', 'LA')}  - #{language}")
            show_empty = 0
          end
        end
        if show_empty == 1
          file.puts("#{get_ris_lable_data(org_field_manager_info, 'language', 'LA')}  - ")
        end
        show_empty = 1
        if resource['description_publisher_sms'].present?
          resource['description_publisher_sms'].each do |publisher|
            if publisher.include?('::')
              publisher = publisher.split('::')[1]
            end
            file.puts("#{get_ris_lable_data(org_field_manager_info, 'publisher', 'PB')}  - #{publisher}")
            show_empty = 0
          end
        end
        if show_empty == 1
          file.puts("#{get_ris_lable_data(org_field_manager_info, 'publisher', 'PB')}  - ")
        end
        file.puts("#{get_ris_lable_data(org_field_manager_info, 'preferred_citation', 'C1')}  - #{get_resource_data(resource, 'description_preferred_citation_ss')}")
        file.puts('DP  - Aviary')
        file.puts("UR  - #{resource_url}")
        file.puts("Y2  - #{myresource_list[resource['id_is']].present? ? myresource_list[resource['id_is']]['updated_at'] : ''}")
        file.puts("N1  - #{myresource_list[resource['id_is']].present? ? myresource_list[resource['id_is']]['note'] : ''}")
        file.puts('ER  - ')
      end
      file.close
      send_file(file_path)
    else
      redirect_back(fallback_location: root_path)
    end
  end
end
