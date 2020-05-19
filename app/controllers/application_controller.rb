# ApplicationController <
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Adds a few additional behaviors into the application controller
  include ApplicationHelper
  include Aviary::CheckOrganization
  protect_from_forgery with: :exception, prepend: true
  before_action :store_user_location!, if: :storable_location?
  before_action :redirect_on_bad_subdomain, :search_param_handler, :clear_session_data, :set_headers
  helper_method :current_organization

  rescue_from CanCan::AccessDenied do |_|
    session[:previous_url] = request.fullpath
    respond_to do |format|
      format.json { head :forbidden }
      format.html { redirect_to forbidden_url }
    end
  end

  def check_if_user_idp; end

  def clear_session_data
    session[:add_visitor] = {} unless params[:controller] == 'home' && %w[index featured_collections featured_resources record_tracking].include?(params[:action])
  end

  def record_last_bread_crumb(path, title)
    path_raw = path.dup
    path_raw[0] = ''
    url_path = root_url(subdomain: current_organization.present?) + path_raw
    session[:last_page] = { path: url_path, title: title.html_safe }
  rescue StandardError => e
    puts e.backtrace.join("\n")
  end

  def encrypted_info
    response = if current_user_is_org_owner_or_admin?
                 crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31], Rails.application.secrets.secret_key_base)
                 crypt.encrypt_and_sign(params[:text_to_be_encrypted])
               else
                 ''
               end
    render json: { encrypted_data: response }
  end

  def search_param_handler
    methods = %w[load_resource_details_template show load_head_and_tombstone_template search_text record_tracking]
    controllers = %w[playlists transcripts indexes]
    session[:solr_params] = '' if params[:controller] != 'collection_resources' && !methods.include?(params[:action]) && params[:controller] != 'catalog'
    session[:search_text] = {} if !controllers.include?(params[:controller]) && !%w[upload].include?(params[:action]) && (params[:controller] != 'collection_resources' && !methods.include?(params[:action]))
    session[:resource_tracking] = {} if (params[:controller] != 'transcripts' && params[:controller] != 'indexes') && !%w[upload].include?(params[:action]) && (params[:controller] != 'collection_resources' && !methods.include?(params[:action]))
    session[:playlist_resource_id] = {} if params[:controller] != 'catalog' && !%w[update_selected_playlist fetch_bulk_edit_resource_list].include?(params[:action])
    if params.key?('resource_file_id') && params['resource_file_id'].present? && params['resource_file_id'] != session[:last_resource_file_id]
      begin
        session[:resource_tracking]['index'] = []
        session[:resource_tracking]['transcript'] = []
        session[:resource_tracking]['collection_resource_file'] = []
      rescue StandardError => e
        puts e.backtrace.join("\n")
      end
    end
    session[:last_resource_file_id] = params['resource_file_id'] if params.key?('resource_file_id') && params['resource_file_id'].present?
  end

  def authenticate_admin!
    if user_signed_in?
      sign_out(@user)
      redirect_to new_admin_session_url
    else
      super
    end
  end

  def record_tracking
    session[:resource_tracking] ||= {}
    session[:resource_tracking] = params['information'].to_enum.to_h if params['request_type'] == 'add'
    respond_to do |format|
      format.html { render json: session[:resource_tracking] }
      format.json { render json: session[:resource_tracking] }
    end
  end

  protected

  def after_sign_in_path_for(resource)
    session[:layout] ||= 'not-collapsed'
    if resource.is_a?(Admin)
      admin_users_url(subdomain: false)
    else
      if resource.first_url.present?
        previous_path = resource.first_url
        resource.update(first_url: '')
      else
        previous_path = session[:previous_url]
        session[:previous_url] = nil
      end
      previous_path || stored_location_for(resource) || root_path
    end
  end

  def set_headers
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def after_sign_out_path_for(resource)
    root_url(resource)
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end
end
