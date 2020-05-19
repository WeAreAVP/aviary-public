# Utilities
module Utilities
  # Utilities::AviaryDomainHandler
  class AviaryDomainHandler < Utilities::BaseUtility
    def initialize
      super
    end

    def self.organization_using_host_type(_organization)
      'subdomain'
    end

    def self.subdomain_handler(organization)
      return unless organization.present?
      if organization_using_host_type(organization) == 'host'
        organization.custom_domain
      else
        (ENV['APP_HOST']).to_s
      end
    end
  end
end
