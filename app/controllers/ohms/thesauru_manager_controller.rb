# frozen_string_literal: true

module Ohms
  # OHMS Integration Controller
  class ThesauruManagerController < ApplicationController
    before_action :authenticate_user!
    before_action :current_thesaurus, only: %i[destroy update edit export]

    def index
      authorize! :manage, current_organization
    end

    def datatable
      authorize! :manage, current_organization
      @field_has_thesaurus = {}
      @org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
      @resource_fields = @org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
      @resource_fields.each_with_index do |(system_name, single_collection_field), _index|
        field_settings = Aviary::FieldManagement::FieldManager.new(single_collection_field, system_name)
        thesaurus = field_settings.info_of_attribute('thesaurus')
        if thesaurus.present? && thesaurus['vocabulary'].present? && thesaurus['vocabulary'].present? && thesaurus['vocabulary']['id']
          @field_has_thesaurus[thesaurus['vocabulary']['id']] ||= []
          @field_has_thesaurus[thesaurus['vocabulary']['id']] << field_settings.label
        end
        if thesaurus.present? && thesaurus['dropdown'].present? && thesaurus['dropdown'].present? && thesaurus['dropdown']['id']
          @field_has_thesaurus[thesaurus['dropdown']['id']] ||= []
          @field_has_thesaurus[thesaurus['dropdown']['id']] << field_settings.label
        end
      end
      respond_to do |format|
        format.html
        format.json { render json: ThesaurusDatatable.new(view_context, current_organization, @field_has_thesaurus) }
      end
    end

    def new
      @ohms_thesaurus = Ohms::OhmsThesauru.new
    end

    def destroy
      begin
        flash[:notice] = @ohms_thesaurus.destroy ? 'deleted successfully.' : t('error_update_again')
      rescue StandardError
        flash[:notice] = t('error_update_again')
      end
      redirect_back(fallback_location: organization_fields_path)
    end

    def assignment_management
      @organization_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
      @resource_fields_settings = @organization_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
      @selected_file = params['thesaurus_id']
      @action_type = params['action_type']
      if params['list_of_fields_dropdown'].present?
        system_name, option_selected = params['list_of_fields_dropdown'].split('||-@||')

        if @resource_fields_settings[system_name].present?
          if params['assignment_option_custom_thesaurus'].to_s == '0'
            @resource_fields_settings[system_name]['thesaurus'] = { params['inlineRadioOptions'].to_s => { 'id' => params['selected_file'], 'assign_to' => option_selected } }
          else
            @resource_fields_settings[system_name]['thesaurus'] = {}
          end
          @organization_field_manager.update_field_settings(@organization_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'sort_order'),
                                                            { 0 => @resource_fields_settings[system_name] }, current_organization, 'resource_fields')
          flash[:notice] = t('updated_successfully')
          redirect_to organization_fields_path
          return
        end
      end
      respond_to do |format|
        format.html { render 'ohms/thesauru_manager/assignment_management', layout: false }
        format.json { render json: {} }
      end
    end

    def create
      @ohms_thesaurus = Ohms::OhmsThesauru.new(ohms_thesaurus_params)
      @ohms_thesaurus.organization_id = current_organization.id
      @ohms_thesaurus = over_write_terms(ohms_thesaurus_params['ohms_integrations_vocabulary'], @ohms_thesaurus)
      @ohms_thesaurus.number_of_terms = @ohms_thesaurus.thesaurus_terms.present? ? @ohms_thesaurus.thesaurus_terms.count : 0
      @ohms_thesaurus.inject_created_by(current_user)
      @ohms_thesaurus.inject_updated_by(current_user)
      respond_to do |format|
        if @ohms_thesaurus.save
          format.html { redirect_to edit_ohms_thesauru_manager_path(@ohms_thesaurus.id), notice: 'Ohms Thesaurus  created successfully.' }
          format.json { render json: { msg: 'Thesaurus  created successfully.', id: @ohms_thesaurus.id } }
        else
          format.html { render :new }
          format.json { render json: { errors: @ohms_thesaurus.errors } }
        end
      end
    end

    def update
      @ohms_thesaurus.organization_id = current_organization.id
      if ohms_thesaurus_params['ohms_integrations_vocabulary'].present? && ohms_thesaurus_params['ohms_integrations_vocabulary'].respond_to?(:read)
        @ohms_thesaurus = if ohms_thesaurus_params[:operation_type] == '0'
                            over_write_terms(ohms_thesaurus_params['ohms_integrations_vocabulary'], @ohms_thesaurus)
                          elsif ohms_thesaurus_params[:operation_type] == '1'
                            append_terms(ohms_thesaurus_params['ohms_integrations_vocabulary'], @ohms_thesaurus)
                          end
      end
      @ohms_thesaurus.number_of_terms = @ohms_thesaurus.thesaurus_terms.present? ? @ohms_thesaurus.thesaurus_terms.count : 0
      @ohms_thesaurus.inject_updated_by(current_user)
      respond_to do |format|
        if @ohms_thesaurus.update(ohms_thesaurus_params)
          format.html { redirect_to edit_ohms_thesauru_manager_path(@ohms_thesaurus.id), notice: 'Thesaurus  created successfully.' }
          format.json { render json: { msg: 'Thesaurus  created successfully.', id: @ohms_thesaurus.id } }
        else
          format.html { render :new }
          format.json { render json: { errors: @ohms_thesaurus.errors } }
        end
      end
    end

    def edit; end

    def export
      thesaurus_list = @ohms_thesaurus.thesaurus_terms.present? ? @ohms_thesaurus.thesaurus_terms : []
      ohms_thesaurus = CSV.generate do |csv|
        csv << thesaurus_list
      end

      send_data ohms_thesaurus, filename: "#{@ohms_thesaurus.title.delete(' ')}_thesaurus_#{Date.today}.csv", type: 'csv'
    end

    def ohms_thesaurus_params
      params.require(:ohms_ohms_thesauru).permit(:title, :description, :status, :thesaurus_terms, :ohms_integrations_vocabulary, :operation_type)
    end

    private

    def current_thesaurus
      @ohms_thesaurus = nil
      id = params[:id].present? ? params[:id] : params[:thesauru_manager_id]
      @ohms_thesaurus = id.present? ? Ohms::OhmsThesauru.find(id) : nil
    end

    def over_write_terms(file, ohms_thesaurus)
      ohms_thesaurus.thesaurus_terms = if file.present?
                                         if file.respond_to?(:read)
                                           file.read.split(',')
                                         else
                                           []
                                         end
                                       else
                                         []
                                       end
      ohms_thesaurus.thesaurus_terms = ohms_thesaurus.thesaurus_terms.flatten.uniq
      ohms_thesaurus
    end

    def append_terms(file, ohms_thesaurus)
      reading = if file.present?
                  if file.respond_to?(:read)
                    file.read.split(',')
                  else
                    []
                  end
                else
                  []
                end
      ohms_thesaurus.thesaurus_terms = ohms_thesaurus.thesaurus_terms + reading
      ohms_thesaurus.thesaurus_terms = ohms_thesaurus.thesaurus_terms.flatten.uniq
      ohms_thesaurus
    end
  end
end
