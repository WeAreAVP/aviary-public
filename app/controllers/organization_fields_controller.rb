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
    @collection_fields = @org_field_manager.organization_field_settings(current_organization, nil)
    @resource_fields = @org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
    @resource_columns_search = @org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'search_sort_order')
    @resource_columns_table = @org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'resource_table_sort_order')
    @indexes_columns_fields = @org_field_manager.organization_field_settings(current_organization, nil, 'index_fields', 'sort_order')
    @part_of_collections = {}
    return unless current_organization.collections.present?
    current_organization.collections.each do |single_collection|
      single_collection_value = single_collection.collection_fields_and_value
      if single_collection_value.present? && single_collection_value.resource_fields.present?
        single_collection_value.resource_fields.each_with_index do |(system_name, _single_collection_field), _index|
          @part_of_collections = OrganizationFieldPresenter.part_of_collection(current_organization, @part_of_collections, system_name, single_collection)
        end
      end
    end
  end

  def new_edit_custom_field
    authorize! :manage, current_organization
    field_type = 'resource_fields'
    field_type = params['field_type'] if params['field_type'].present?
    meta_field = if params[:methodtype] == 'new'
                   {
                     label: '',
                     system_name: '',
                     field_type: '',
                     is_required: false,
                     is_public: false,
                     is_default: false,
                     is_vocabulary: false,
                     vocabulary: [],
                     help_text: '',
                     is_repeatable: false,
                     is_internal_only: false,
                     field_configuration: {},
                     field_level: 'collection',
                     sort_order: 0,
                     display: true
                   }
                 elsif params[:methodtype] == 'edit'
                   field_information = @org_field_manager.organization_field_settings(current_organization, nil, field_type)
                   field_information[params['system_name']]
                 end
    source_type = field_type
    render partial: 'organization_fields/custom_fields', locals: { meta_field_info: meta_field, source_type: source_type }
  end

  def index_fields_edit
    authorize! :manage, current_organization

    @index_columns_collection = @org_field_manager.organization_field_settings(current_organization, nil, 'index_fields', 'sort_order')

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
      collection = Collection.find_by_id(params['collection_id'])
      @collection_field_manager.delete_field(collection, params['type'], params['system_name'])
      flash[:notice] = 'Field deleted from this collection successfully'
    end
    redirect_back(fallback_location: root_path)
  end

  def assignment_management
    authorize! :manage, current_organization
    case params['js_action']
    when 'collection_list'
      @collections_list = {}
      current_organization.collections.each do |single_collection|
        single_collection_value = single_collection.collection_fields_and_value
        if params[:action_type] == '1'
          @collections_list[single_collection.id] = single_collection.title if single_collection_value.present? && single_collection_value.resource_fields[params['field']].present?
        elsif params[:action_type] == '0'
          @collections_list[single_collection.id] = single_collection.title if single_collection_value.blank? || single_collection_value.resource_fields[params['field']].blank?
        end
      end
    when 'assignField'
      collection = params[:collection_ids].present? ? Collection.where(id: params[:collection_ids]) : nil

      if collection.present?
        case params[:action_type]
        when '0'
          update_information = { 'system_name' => params['field'], 'status' => true, 'tombstone' => false, 'sort_order' => 0 }
          @collection_field_manager.update_field_settings_collection(update_information, collection, 'resource_fields')
        when '1'
          collection.each do |single_collection|
            @collection_field_manager.delete_field(single_collection, 'resource_fields', params['field'])
          end

        end
      end
    end

    respond_to do |format|
      format.html { render 'organization_fields/assignment_management', layout: false }
      format.json { render json: {} }
    end
  end

  def update_index_template
    authorize! :manage, current_organization
    current_organization.index_template = params['index_template'].to_i
    current_organization.save
    UpdateDefaultIndexTemplateJob.perform_later(current_organization, 'organization', params['index_template'])
    flash[:notice] = 'Template updated successfully'
    redirect_back(fallback_location: organization_fields_path)
  end

def update_information
    authorize! :manage, current_organization

    case params['js_action']
    when 'updateSort', 'updateRis'
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
    render json: { response: @org_field_manager.organization_field_settings(current_organization, params[:id], 'resource_fields') }
  end

  def create; end

  private

  def field_manager
    @org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
    @collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
  end
end
