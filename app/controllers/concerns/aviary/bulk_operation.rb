# controllers/concerns/bulk_operation.rb
# Module Aviary::BulkOperation
# The module is written to do bulk operation
#
# Author:: Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary::BulkOperation
  extend ActiveSupport::Concern

  def bulk_resource_list
    current_key = params['type'] == 'collection_resource_files' ? :resource_file_list_bulk_edit : :resource_list_bulk_edit
    current_key = :file_index_bulk_edit if params['type'] == :file_index_bulk_edit.to_s
    current_key = :file_transcript_bulk_edit if params['type'] == :file_transcript_bulk_edit.to_s
    current_key = :interview_bulk if params['type'] == :interview_bulk.to_s
    current_key = :collection_bulk_edit if params['type'] == :collection_bulk_edit.to_s
    collection_resource_file_id = params['type'] == 'collection_resource_files' ? params['collection_resource_file_id'] : params['collection_resource_id']
    collection_resource_file_id = params['collection_resource_file_id'] if [:file_index_bulk_edit.to_s, :file_transcript_bulk_edit.to_s, :interview_bulk.to_s].include?(params['type'])
    collection_resource_file_id = params['id'] if [:interview_bulk.to_s].include?(params['type'])
    collection_resource_file_id = params['collection_id'] if [:collection_bulk_edit.to_s].include?(params['type'])
    session[current_key] ||= []
    session['is_selected_all'] ||= false
    if params[:status] == 'add'
      if params[:bulk] == '1' && params[:ids].present?
        if params[:ids] == 'all'
          session['is_selected_all'] = true
          search_info = { search: { value: params[:searchValue].present? ? params[:searchValue] : '' } }
          table_of_caller = 'organization_id_is'
          limit_resource = "#{table_of_caller}:#{current_organization.id}"
          data = if params['type'] == 'collection_resource_files'
                   CollectionResourceFile.fetch_file_list(0, 0, 'id_is', 'desc', search_info, limit_resource, { export: true, current_organization: current_organization })
                 else
                   organization_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
                   resource_fields = organization_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'resource_table_sort_order')
                   CollectionResource.fetch_resources(1, 100_000_000, 'id_is', 'desc', search_info.merge(fl: 'id_is'), limit_resource,
                                                      resource_fields: resource_fields, export: false, current_organization: current_organization)
                 end
          records_ids = data.first.present? ? data.first.pluck('id_is') : []
          records_ids.each do |single_id|
            session[current_key] << single_id.to_s unless session[current_key].include? single_id.to_s
          end
        else
          params[:ids].each do |single_id|
            session[current_key] << single_id unless session[current_key].include? single_id
          end
        end
      elsif params[:bulk] != '1'
        session[current_key] << collection_resource_file_id unless session[current_key].include? collection_resource_file_id
        session['is_selected_all'] = false
      end
    elsif params[:status] == 'remove'
      if params[:bulk] == '1'
        params[:ids].each do |single_id|
          session[current_key].delete(single_id) if session[current_key].include? single_id
        end
      elsif session[current_key].include? collection_resource_file_id
        session[current_key].delete(collection_resource_file_id)
      end
      session['is_selected_all'] = false
    end
    respond_to do |format|
      format.json { render json: [ids: session[current_key].join(','), status: :created, is_selected_all: session['is_selected_all'], error: flash[:danger] ||= '', message: 'clear'] }
    end
  end

  def update_progress_files
    count = 0
    begin
      case params['bulk_edit_type_of_bulk_operation']
      when 'bulk_delete'
        count = params[:ids].length.to_i - CollectionResourceFile.where(id: params[:ids]).length.to_i
      when 'change_status'
        count = CollectionResourceFile.where(id: params[:ids], access: params[:access_type]).length
      when 'downloadable'
        count = CollectionResourceFile.where(id: params[:ids], is_downloadable: ActiveRecord::Type::Boolean.new.cast(params[:is_downloadable])).length
      end
    rescue StandardError
      count = 0
    end
    respond_to do |format|
      format.json { render json: [count: count, action: 'update_progress_files', status: :created, error: flash[:danger] ||= ''] }
    end
  end

  def update_progress
    count = 0
    begin
      case params[:bulk_edit_type_of_bulk_operation]
      when 'bulk_delete'
        count = params[:ids].length.to_i - CollectionResource.where(id: params[:ids]).length.to_i
      when 'change_status'
        count = CollectionResource.where(id: params[:ids], access: params[:bulk_edit_status]).length
      when 'change_media_file_status'
        access_update = params[:bulk_edit][:status] == 'access_private' ? 0 : 1
        count = CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit], access: access_update).length
      when 'change_resource_index_status'
        access_update = params[:bulk_edit][:status] == 'access_private' ? 0 : 1
        count = FileIndex.where(collection_resource_file_id: CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit]).pluck(:id), is_public: access_update).length
      when 'change_resource_transcript_status'
        access_update = params[:bulk_edit][:status] == 'access_private' ? 0 : 1
        count = FileTranscript.where(collection_resource_file_id: CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit]).pluck(:id), is_public: access_update).length
      when 'change_featured'
        count = if params[:bulk_edit_featured] == 'Yes'
                  CollectionResource.where(id: params[:ids], is_featured: true).length
                else
                  CollectionResource.where(id: params[:ids], is_featured: false).length
                end
      when 'assign_to_playlist_content'
        count = PlaylistResource.where(playlist_id: params[:bulk_edit][:collections], collection_resource_id: params[:ids]).length
      when 'assign_to_collection'
        count = CollectionResource.where(id: params[:ids], collection_id: params[:bulk_edit][:collections]).length
      end
    rescue StandardError
      count = 0
    end
    respond_to do |format|
      format.json { render json: [count: count, action: 'update_progress', status: :created, error: flash[:danger] ||= ''] }
    end
  end

  def fetch_bulk_edit_resource_list
    @resources = nil
    @resources = if session[:file_index_bulk_edit].present? && params[:type] == :file_index_bulk_edit.to_s
                   FileIndex.where(id: (session[:file_index_bulk_edit] - [nil]))
                 elsif session[:file_transcript_bulk_edit].present? && params[:type] == :file_transcript_bulk_edit.to_s
                   FileTranscript.where(id: (session[:file_transcript_bulk_edit] - [nil]))
                 elsif params[:type] == 'collection_resource_file' && !session[:resource_file_list_bulk_edit].empty?
                   CollectionResourceFile.where(id: session[:resource_file_list_bulk_edit])
                 elsif session[:search_playlist_id].present? && !session[:search_playlist_id].empty?
                   CollectionResource.where(id: session[:search_playlist_id].to_a.flatten.uniq!)
                 elsif session[:interview_bulk].present?
                   Interviews::Interview.where(id: session[:interview_bulk])
                 elsif session[:resource_list_bulk_edit].present? && !session[:resource_list_bulk_edit].empty?
                   CollectionResource.where(id: session[:resource_list_bulk_edit])
                 elsif session[:collection_bulk_edit].present? && !session[:collection_bulk_edit].empty?
                   Collection.where(id: session[:collection_bulk_edit])
                 end
    render partial: 'fetch_bulk_edit_resource_list'
  end

  def bulk_edit_operation
    msg = []
    if params.key?(:bulk_edit) && params[:bulk_edit].key?('type_of_bulk_operation') && !session[:resource_list_bulk_edit].empty?
      begin
        case params[:bulk_edit][:type_of_bulk_operation]
        when 'bulk_delete'
          CollectionResource.where(id: session[:resource_list_bulk_edit]).destroy_all
          msg = " #{session[:resource_list_bulk_edit].length} resources are deleted from system"
        when 'change_status'
          CollectionResource.where(id: session[:resource_list_bulk_edit]).update(access: params[:bulk_edit][:status])
          msg = " Status for #{session[:resource_list_bulk_edit].length} resource(s) have been updated successfully"
        when 'change_media_file_status'
          access_update = params[:bulk_edit][:child_status] == 'access_private' ? 0 : 1
          CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit]).update(access: access_update)
          msg = " Status of media file for #{session[:resource_list_bulk_edit].length} resource(s) have been updated successfully"
        when 'change_resource_index_status'
          access_update = params[:bulk_edit][:child_status] == 'access_private' ? 0 : 1
          FileIndex.where(collection_resource_file_id: CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit]).pluck(:id)).update(is_public: access_update)
          msg = " Status for #{session[:resource_list_bulk_edit].length} indexes have been updated successfully"
        when 'change_resource_transcript_status'
          access_update = params[:bulk_edit][:child_status] == 'access_private' ? 0 : 1
          FileTranscript.where(collection_resource_file_id: CollectionResourceFile.where(collection_resource_id: session[:resource_list_bulk_edit]).pluck(:id)).update(is_public: access_update)
          msg = " Status for #{session[:resource_list_bulk_edit].length} transcripts have been updated successfully"
        when 'change_featured'
          if params[:bulk_edit][:featured] == 'Yes'
            CollectionResource.where(id: session[:resource_list_bulk_edit]).update(is_featured: true)
            msg = " #{session[:resource_list_bulk_edit].length} resource(s) are marked as featured successfully"
          else
            CollectionResource.where(id: session[:resource_list_bulk_edit]).update(is_featured: false)
            msg = " #{session[:resource_list_bulk_edit].length} resource(s) are marked as non-featured successfully"
          end
        when 'assign_to_playlist_content'
          playlists = Playlist.find(params[:bulk_edit][:playlists])
          sorter = 1
          CollectionResource.where(id: session[:resource_list_bulk_edit]).each do |single_collection_resource|
            PlaylistPresenter.add_resource_to_playlist(single_collection_resource.id, playlists, current_user, sorter)
            sorter += 1
          end
          msg = "#{session[:resource_list_bulk_edit].length} resource(s) are added to playlist successfully"
        when 'assign_to_collection'
          CollectionResource.where(id: session[:resource_list_bulk_edit]).update(collection_id: params[:bulk_edit][:collections])
          msg = "Collection of #{session[:resource_list_bulk_edit].length} resource(s) are updated successfully"
        end
      rescue StandardError
        msg = t('error_update_again')
      end
      session[:resource_list_bulk_edit] = []
    else
      msg << 'No Resource selected'
    end
    respond_to do |format|
      format.json { render json: [message: msg, action: 'bulk_edit_operation', status: :created, error: flash[:danger] ||= ''] }
    end
  end
end
