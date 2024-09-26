# controllers/organization_fields_controller.rb
#
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OrganizationFieldsController < ApplicationController
  before_action :field_manager
  before_action :authenticate_user!
  include ApplicationHelper
  include OrganizationFieldsHelper

  def index
    authorize! :manage, current_organization
    @collection_fields = field_settings(current_organization, nil)
    @resource_fields = field_settings(current_organization, nil, 'resource_fields')
    @resource_columns_search = field_settings(current_organization, nil, 'resource_fields', 'search_sort_order')
    @resource_columns_table = field_settings(current_organization, nil, 'resource_fields', 'resource_table_sort_order')
    @indexes_columns_fields = field_settings(current_organization, nil, 'index_fields', 'sort_order')

    @part_of_collections = part_of_collections_hash
  end

  def new_edit_custom_field
    authorize! :manage, current_organization

    field_type = params['field_type'].presence || 'resource_fields'

    meta_field = case params[:methodtype]
                 when 'new'
                   new_field_hash
                 when 'edit'
                   edit_field_hash(field_type)
                 end

    render partial: 'organization_fields/custom_fields', locals: { meta_field_info: meta_field, source_type: field_type }
  end

  def index_fields_edit
    authorize! :manage, current_organization

    @index_columns_collection = field_settings(current_organization, nil, 'index_fields', 'sort_order')
    meta_field = @index_columns_collection[params[:field_name]]

    render partial: 'organization_fields/index_metadata_fields.html', locals: { meta_field: meta_field }
  end

  def delete_field
    authorize! :manage, current_organization

    case params['delete_type']
    when 'organization_level'
      flash[:notice] = 'Field deleted from this organization successfully'
      @org_field_manager.delete_field(current_organization, params['system_name'], params['type'])
    else
      collection = Collection.find_by(id: params['collection_id'])
      @collection_field_manager.delete_field(collection, params['type'], params['system_name'])
      flash[:notice] = 'Field deleted from this collection successfully'
    end

    redirect_back(fallback_location: root_path)
  end

  def assignment_management
    authorize! :manage, current_organization

    case params['js_action']
    when 'collection_list'
      @collections_list = generate_collections_list
    when 'assignField'
      handle_assign_field
    end

    respond_to do |format|
      format.html { render 'organization_fields/assignment_management', layout: false }
      format.json { render json: {} }
    end
  end

  def update_index_template
    authorize! :manage, current_organization

    current_organization.update(index_template: params['index_template'].to_i)
    UpdateDefaultIndexTemplateJob.perform_later(current_organization, 'organization', params['index_template'])

    flash[:notice] = 'Template updated successfully'
    redirect_back(fallback_location: organization_fields_path)
  end

  def update_information
    authorize! :manage, current_organization

    message = 'information updated successfully'
    case params['js_action']
    when 'updateSort'
      update_sort_or_ris
    when 'updateSortCollection'
      update_sort_collection('resource_fields')
    when 'updateSortCollectionIndexFields'
      update_sort_collection('index_fields')
    when 'editVocabulary'
      params[:type] == 'index_fields' ? update_index_fields_vocabulary : edit_vocabulary
    when 'addFieldToSelectCollection'
      add_field_to_select_collection
    when 'updateInformation'
      message, type = create_update_organization_fields
    end

    if request.xhr?
      render json: { response: message }
    else
      flash[type] = message
      redirect_back(fallback_location: organization_fields_path)
    end
  end

  def edit
    authorize! :manage, current_organization
    render json: { response: @org_field_manager.organization_field_settings(current_organization, params[:id],
                                                                            'resource_fields') }
  end

  def create; end

  private

  def field_manager
    @org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
    @collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
  end
end
