# controllers/concerns/manage_organization.rb
# Module Aviary::CheckOrganization
# The module is written to get manage common methods those are needed or the organization and super admins
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
module Aviary::ManageOrganization
  extend ActiveSupport::Concern

  def new
    @organization = Organization.new
  end

  def edit
    authorize! :manage, current_organization unless admin_signed_in?
  end

  def display_settings
    authorize! :manage, current_organization
  end

  def update
    authorize! :manage, current_organization unless admin_signed_in?
    if @organization.update(org_params)
      respond_to do |format|
        flash[:notice] = 'Organization updated successfully.'
        format.html { redirect_back(fallback_location: root_path) }
        format.json { render json: [@organization], status: :ok, location: @organization }
      end
    else
      begin
        current_action = request.referer.include?('display_settings') ? :display_settings : :edit
      rescue StandardError
        current_action = :edit
      end
      respond_to do |format|
        format.html { render current_action }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  def search_configuration
    authorize! :manage, current_organization
    if params['sort_info_search'].present? && request.post?
      current_organization.update(search_facet_fields: params['sort_info_search'])
      redirect_back(fallback_location: root_path)
    end
    @dynamic_fields = current_organization.search_facet_fields.present? ? JSON.parse(current_organization.search_facet_fields) : current_organization.all_org_fields
    @organization = current_organization
  end

  private

  def set_organization
    @organization = if admin_signed_in?
                      Organization.find(params[:id])
                    else
                      current_organization
                    end
  end

  def org_params
    params.require(:organization).permit(:name, :url, :description, :address_line_1,
                                         :address_line_2, :city, :state, :country, :zip, :logo_image,
                                         :banner_image, :display_banner, :logo_image, :status, :storage_type, :banner_image,
                                         :banner_title_text, :banner_type, :banner_slider_resources, :default_tab_selection,
                                         :title_font_color, :title_font_family, :title_font_size, :favicon, :hide_on_home,
                                         :custom_domain, :custom_url_for_resource, :search_panel_bg_color, :search_panel_font_color)
  end
end
