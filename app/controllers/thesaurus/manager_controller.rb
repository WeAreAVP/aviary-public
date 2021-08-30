# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

module Thesaurus
  # OHMS Integration Controller
  class ManagerController < ApplicationController
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
        format.json { render json: InformationDatatable.new(view_context, current_organization, @field_has_thesaurus) }
      end
    end

    def new
      authorize! :manage, current_organization
      @thesaurus = ::Thesaurus::Thesaurus.new
    end

    def destroy
      authorize! :manage, current_organization

      begin
        flash[:notice] = if @thesaurus.parent_id.to_i != 1
                           @thesaurus.destroy ? 'deleted successfully.' : t('error_update_again')
                         else
                           t('error_update_again')
                         end
      rescue StandardError
        flash[:notice] = t('error_update_again')
      end
      redirect_back(fallback_location: organization_fields_path)
    end

    def assignment_management
      authorize! :manage, current_organization
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
            @resource_fields_settings[system_name] = @resource_fields_settings[system_name].except!('thesaurus')
          end
          @organization_field_manager.update_field_settings(@organization_field_manager.organization_field_settings(current_organization, nil, 'resource_fields', 'sort_order'),
                                                            { 0 => @resource_fields_settings[system_name] }, current_organization, 'resource_fields')
          flash[:notice] = t('updated_successfully')
          redirect_to organization_fields_path
          return
        end
      end
      respond_to do |format|
        format.html { render 'thesaurus/manager/assignment_management', layout: false }
        format.json { render json: {} }
      end
    end

    def create
      authorize! :manage, current_organization

      @thesaurus = ::Thesaurus::Thesaurus.new(thesaurus_params)
      @thesaurus.organization_id = current_organization.id
      @thesaurus.organization = current_organization
      @thesaurus.number_of_terms = 0

      @thesaurus.inject_created_by(current_user)
      @thesaurus.inject_updated_by(current_user)
      respond_to do |format|
        if @thesaurus.save
          @thesaurus = over_write_terms(thesaurus_params['ohms_integrations_vocabulary'], @thesaurus)
          @thesaurus.number_of_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: @thesaurus.id).count
          @thesaurus.save
          format.html { redirect_to edit_thesaurus_manager_path(@thesaurus.id), notice: 'Ohms Thesaurus  created successfully.' }
          format.json { render json: { msg: 'Thesaurus  created successfully.', id: @thesaurus.id } }
        else
          format.html { render :new }
          format.json { render json: { errors: @thesaurus.errors } }
        end
      end
    end

    def update
      authorize! :manage, current_organization
      @thesaurus.organization_id = current_organization.id
      if thesaurus_params['ohms_integrations_vocabulary'].present? && thesaurus_params['ohms_integrations_vocabulary'].respond_to?(:read)
        @thesaurus = if thesaurus_params[:operation_type] == '0'
                       over_write_terms(thesaurus_params['ohms_integrations_vocabulary'], @thesaurus)
                     elsif thesaurus_params[:operation_type] == '1'
                       append_terms(thesaurus_params['ohms_integrations_vocabulary'], @thesaurus)
                     end
      end
      @thesaurus.number_of_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: @thesaurus.id).count
      @thesaurus.inject_updated_by(current_user)
      respond_to do |format|
        if @thesaurus.update(thesaurus_params)
          format.html { redirect_to edit_thesaurus_manager_path(@thesaurus.id), notice: 'Thesaurus  created successfully.' }
          format.json { render json: { msg: 'Thesaurus  created successfully.', id: @thesaurus.id } }
        else
          format.html { render :new }
          format.json { render json: { errors: @thesaurus.errors } }
        end
      end
    end

    def edit
      authorize! :manage, current_organization
      error = t('access_information_not_available')
      return redirect_to organization_fields_path, flash: { error: error } if @thesaurus.parent_id.to_i > 0 || ::Thesaurus::Thesaurus.where(id: @thesaurus, organization_id: current_organization.id).blank?
    end

    def export
      authorize! :manage, current_organization
      row = []
      all_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: @thesaurus.id)
      thesaurus = CSV.generate do |csv|
        all_terms.each do |single_term|
          row << single_term.term.strip
        end
        csv << row
      end
      send_data thesaurus, filename: "#{@thesaurus.title.delete(' ')}_thesaurus_#{Date.today}.csv", type: 'csv'
    end

    def thesaurus_params
      params.require(:thesaurus_thesaurus).permit(:title, :description, :status, :thesaurus_terms, :ohms_integrations_vocabulary, :operation_type)
    end

    def autocomplete
      term = params[:term].to_s
      t_id = params['tId']
      type_of_list = params['typeOfList']
      json_data = []
      json_data = if type_of_list == 'thesaurus'
                    thesaurus_information = ::Thesaurus::Thesaurus.find_by(id: t_id)
                    thesaurus_id = thesaurus_information.present? && thesaurus_information.parent_id.present? && thesaurus_information.parent_id > 0 ? thesaurus_information.parent_id : t_id

                    thesaurus = if term.present?
                                  terms_all = term.split(' ')
                                  terms_all = terms_all.map { |item| "*#{item}*" }
                                  ::Thesaurus::ThesaurusTerms.select('id, term').where('MATCH(term) AGAINST(? IN BOOLEAN MODE)', terms_all.join(' ').to_s).where(thesaurus_information_id: thesaurus_id).order('term asc').limit(10)
                                else
                                  ::Thesaurus::ThesaurusTerms.select('id, term').where(thesaurus_information_id: thesaurus_id).order('term asc').limit(10)
                                end
                    thesaurus.map { |e| { id: e.id, label: e.term, value: e.term } } if thesaurus.present?
                  elsif %w[dropdown vocabulary].include? type_of_list
                    @organization_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
                    @resource_fields_settings = @organization_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
                    field_settings = Aviary::FieldManagement::FieldManager.new(@resource_fields_settings[t_id], t_id)
                    if type_of_list == 'dropdown'
                      if field_settings.dropdown_options.present?
                        field_settings.dropdown_options.each do |single|
                          json_data << { id: single, label: single } if count_em(single, term) > 0
                        end
                        json_data
                      else
                        []
                      end
                    elsif type_of_list == 'vocabulary'
                      if field_settings.vocabulary_list.present?
                        field_settings.vocabulary_list.each do |single|
                          json_data << { id: single, label: single } if count_em(single, term) > 0
                        end
                        json_data
                      else
                        []
                      end
                    else
                      []
                    end
                  end
      json_data ||= []
      render json: json_data
    end

    private

    def current_thesaurus
      @thesaurus = nil
      id = params[:id].present? ? params[:id] : params[:manager_id]
      @thesaurus = id.present? ? ::Thesaurus::Thesaurus.find_by_id(id) : nil
    end

    def over_write_terms(file, thesaurus)
      thesaurus_terms = if file.present?
                          file.respond_to?(:read) ? file.read.strip.gsub('"""', '"').split(/\s*,\s*/) : []
                        else
                          []
                        end
      all_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus.id)
      all_terms.destroy_all if all_terms.present?
      manage_terms(thesaurus_terms, thesaurus)
    end

    def append_terms(file, thesaurus)
      thesaurus_terms = if file.present?
                          file.respond_to?(:read) ? file.read.strip.gsub('"""', '"').split(/\s*,\s*/) : []
                        else
                          []
                        end
      manage_terms(thesaurus_terms, thesaurus)
    end

    def manage_terms(thesaurus_terms, thesaurus)
      if thesaurus_terms.present?
        ::Thesaurus::ThesaurusTerms.transaction do
          thesaurus_terms.each do |single_term|
            ::Thesaurus::ThesaurusTerms.create(thesaurus_information_id: thesaurus.id, term: single_term) unless ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus.id, term: single_term).present?
          end
        end
      end
      thesaurus
    end
  end
end
