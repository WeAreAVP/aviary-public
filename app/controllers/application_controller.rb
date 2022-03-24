# ApplicationController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # layout :determine_layout if respond_to? :layout
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

  def open(url, _allow_redirections = '')
    res = url =~ URI::DEFAULT_PARSER.make_regexp
    if res.nil?
      File.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)

    else
      URI.open(url, allow_redirections: :all, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    end
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
    response = if current_user_is_org_user?(current_organization)
                 collection_resource_id = params['collection_resource_id']
                 update_access_url_id = params['update_access_url_id']
                 if params['type'] == 'ever_green_url'
                   existing_resource = PublicAccessUrl.where(collection_resource_id: collection_resource_id, access_type: 'ever_green_url')
                   if existing_resource.present?
                     update_access_url_id = existing_resource.first.id
                     existing_resource.where.not(id: update_access_url_id).delete_all
                   end
                 end
                 information = { start_time: params['start_time_status'].to_s.to_boolean? ? params['start_time'] : nil, end_time: params['end_time_status'].to_s.to_boolean? ? params['end_time'] : nil,
                                 start_time_status: params['start_time_status'], end_time_status: params['end_time_status'] }
                 public_access_url = update_access_url_id.present? ? PublicAccessUrl.find_by_id(update_access_url_id) : nil

                 object = { access_type: params['type'], status: true, collection_resource_id: collection_resource_id, url: '' }
                 object[:duration] = params['type'] == 'ever_green_url' ? 'Ongoing' : params['duration']
                 object[:information] = params['type'] == 'ever_green_url' ? nil : information.to_json
                 public_access_url = if public_access_url.present?
                                       public_access_url.update(object)
                                       public_access_url
                                     else
                                       PublicAccessUrl.create(object)
                                     end
                 encrypted_string = EnDecryptor.encrypt(public_access_url.id.to_s + '--' + random_string).strip
                 param_noid = { noid: CollectionResource.find(collection_resource_id).noid, host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization), access: encrypted_string }
                 unless params['type'] == 'ever_green_url'
                   param_noid[:t] = human_to_seconds(information[:start_time]) if information[:start_time].present?
                   param_noid[:e] = human_to_seconds(information[:end_time]) if information[:end_time].present?
                   param_noid[:auto_play] = 'true' if params[:auto_play].present? && params[:auto_play].to_s.to_boolean? == true
                 end
                 url = noid_url(param_noid)
                 public_access_url.update(url: url)
                 url
               else
                 ''
               end
    render json: { encrypted_data: CGI.unescape(response) }
  end

  def remove_image_for_assets
    remove_image(eval(params['target_type'].capitalize).find_by_id(params['target_id']), params['target_attr']) if params['target_type'].present? && params['target_id'].present? && params['target_attr'].present?
    redirect_back(fallback_location: root_path)
  end

  def search_param_handler
    methods = %w[load_resource_details_template show load_head_and_tombstone_template search_text record_tracking list_playlist_items]
    controllers = %w[playlists transcripts indexes playlist_resources]
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
    headers['Access-Control-Allow-Origin'] = root_url.chop
  end

  def after_sign_out_path_for(resource)
    root_url(resource)
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def remove_image(model_object, attribute)
    # @param [Object]  model_object
    # @param [Object]  attribute
    # @return [Object]

    val = if Organization.first.class.name == 'Organization' && attribute == 'banner_image'
            open("#{Rails.root}/public/aviary_default_banner.png")
          elsif Organization.first.class.name == 'Collection' && attribute == 'image'
            open("#{Rails.root}/public/aviary_default_collection.png")
          end
    model_object.update_attributes(attribute.to_s => val)
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end
end
