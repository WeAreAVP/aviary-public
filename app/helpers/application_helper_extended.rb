# ApplicationHelperExtended
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
    ].any?
  end
end
