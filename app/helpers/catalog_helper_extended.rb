# CatalogHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module CatalogHelperExtended
  def self.organization_home_search_container_styles(request, current_organization)
    return unless request.fullpath == '/collection'

    if current_organization.display_banner
      "background-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)),
                         url(#{current_organization.banner_image.url}) !important;
      min-height: 300px !important;"
    else
      "background-color: #{current_organization.search_panel_bg_color.present? ? current_organization.search_panel_bg_color : '#f05d1f'}"
    end
  end
end
