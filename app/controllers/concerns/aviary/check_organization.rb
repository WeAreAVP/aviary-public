# controllers/concerns/check_organization.rb
# Module Aviary::CheckOrganization
# The module is written to get the current organization and manage its redirect
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
module Aviary::CheckOrganization
  extend ActiveSupport::Concern

  def current_organization
    Organization.first
  end

  def redirect_on_bad_subdomain
    return if request.subdomain == 'www'
    if !valid_custom_domain?(request.host) && !valid_subdomain?(request.subdomain)
      redirect_url = not_found_url(subdomain: false)
      redirect_to redirect_url
      false
    end
    if current_organization
      return if current_organization.status?
      return redirect_to not_found_url(subdomain: false) if !current_organization.status? && request[:controller] == 'home'
      return if !current_organization.status? && %w[update update_billing account renew destroy].include?(request[:action])
      redirect_to account_organization_url(host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization))
    end
    true
  end

  def valid_subdomain?(subdomain)
    organization = Organization.first
    subdomain.present? && organization.nil? ? false : true
  end

  def valid_custom_domain?(custom_domain)
    organization = Organization.first
    custom_domain.present? && organization.nil? ? false : true
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, current_organization, request.ip, request)
  end
end
