# Utilities
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
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
        ENV.fetch('APP_HOST', nil).to_s
      end
    end
  end
end
