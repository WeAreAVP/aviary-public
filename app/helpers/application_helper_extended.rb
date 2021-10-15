# ApplicationHelperExtended
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module ApplicationHelperExtended
  def role_type(user, organization)
    role_name = Role.all_user_types[4]
    if user.present?
      if user.organization_users.present? && organization.present?
        role_user = user.organization_users.where(organization_id: organization.id)
        role_name = if role_user.present? && role_user.first.role.present?
                      role_user.first.role.system_name
                    else
                      Role.all_user_types[3]
                    end
      else
        role_name = Role.all_user_types[3]
      end
    end
    role_name
  end

  def search_panel_bg_color
    organization_layout? && !current_organization.search_panel_bg_color.blank? && current_organization.search_panel_bg_color != 'default' ? ".search-result-visual{ background: #{current_organization.search_panel_bg_color} !important } " : '#f05d1f'
  end

  def search_panel_font_color
    classes = '.simple_option_search, .simple_start_over, .advance_option_search, .theme_font_color'
    organization_layout? && !current_organization.search_panel_font_color.blank? && current_organization.search_panel_font_color != 'default' ? "#{classes} { color: #{current_organization.search_panel_font_color} !important } " : ''
  end

  def banner_style
    organization = current_organization
    style = ''
    style += "font-size:#{organization.title_font_size};" if current_organization.title_font_size.present?
    style += "color:#{organization.title_font_color};" if current_organization.title_font_color.present?
    style += "font-family:#{organization.title_font_family};" if current_organization.title_font_family.present? && current_organization.title_font_family != 'default'
    style
  end

  def modern_browser?(browser)
    [
      browser.chrome?('>= 65'),
      browser.safari?('>= 10'),
      browser.firefox?('>= 52'),
      browser.ie?('>= 11') && !browser.compatibility_view?,
      browser.edge?('>= 15'),
      browser.opera?('>= 50'),
      browser.facebook? && browser.safari_webapp_mode? && browser.webkit_full_version.to_i >= 602
    ].any? || browser.device.mobile?
  end

  def allowed_query_params
    ['keywords[]', 'selected_transcript', 'selected_index', 'embed', 't', 'e', 'auto_play', 'media_player', 'media',
     'access', 'offset', 'from_playlist', 'playlist_view_type', 'resource_file_id', 'f', 'search_field', 'search_type', 'title_text', 'type_of_search',
     'id', 'collection_id', 'collection_resource_id', 'collection_resource_file_id', 'organization_id', 'playlist_id', 'playlist_resource_id',
     'utf8', 'update_advance_search', 'search_type', 'transliteration_status', 'f', 'keywords', 'title_text',
     'resource_description', 'indexes', 'transcript', 'collection_title', 'op', 'search_field', 'type_of_search', 'type_of_field_selector',
     'sort', 'search_field', 'commit']
  end

  def check_params(request_url, only_params = false)
    keys_to_extract = allowed_query_params
    query_hash = Rack::Utils.parse_query(URI.parse(request_url).query).select { |key, _| keys_to_extract.include? key }
    return query_hash if only_params
    path = query_hash.empty? ? request.path : "#{request.path}?#{CGI.unescape(query_hash.to_query).gsub('[][]', '[]')}"
    root_url.chop + path
  end
end
