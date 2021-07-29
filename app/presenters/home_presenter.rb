# CollectionResourceFilePresenter
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class HomePresenter < BasePresenter
  include ApplicationHelper
  def self.manage_home_tracking(cookies, current_organization, session, ahoy)
    if (Ahoy::Visit.where(visit_token: cookies['ahoy_visit']).where.not(organization_id: nil).blank? || session[:add_visitor].blank? ||
        session[:add_visitor][current_organization.id].nil? || (session[:add_visitor].present? && session[:add_visitor][current_organization.id])) && current_organization.present?
      cookies.delete :ahoy_visit
      cookies.delete :ahoy_visitor
      ahoy.track_visit(defer: false)
      session[:add_visitor] ||= {}
      session[:add_visitor][current_organization.id] = false
    end
  end

  def self.unique_identifier_param_manager(request_params, current_organization)
    custom_unique_identifier = request_params[:custom_unique_identifier]
    raw_params = custom_unique_identifier.split('/')
    custom_unique_identifier = raw_params[0].present? ? raw_params[0] : ''
    sequential_number_of_media_file = raw_params[1].present? ? raw_params[1] : ''
    seconds_to_start_time = raw_params[2].present? ? raw_params[2] : ''
    collection_resource = CollectionResource.where(custom_unique_identifier: custom_unique_identifier)
    collection_resource = collection_resource.where(collection_id: current_organization.collections.pluck(:id)) if current_organization.present?
    collection_resource = collection_resource.first
    [sequential_number_of_media_file, seconds_to_start_time, collection_resource]
  rescue StandardError
    [nil, nil, nil]
  end
end
