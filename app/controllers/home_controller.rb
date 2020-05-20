# HomeController
class HomeController < ApplicationController
  include CollectionResourceFileHelper

  def index
    organization = current_organization
    title_bread_crumb = organization.present? ? "Back to <strong>#{organization.name.truncate(25, omission: '...')}</strong>" : 'Back to Aviary Home'
    record_last_bread_crumb(request.fullpath, title_bread_crumb)
    HomePresenter.manage_home_tracking(cookies, organization, session, ahoy)
    cookies[:update_pop_bypass] = true if params[:update_pop_bypass]
  end

  def featured_collections
    organization = current_organization
    if organization
      if current_user.present?
        user_current_organization = current_user.organization_users.active.where(organization_id: organization.id)
        @featured_collections = if user_current_organization.present?
                                  Collection.where(organization: organization).order_feature_name
                                else
                                  organization.collections.public_collections.order_feature_name
                                end
      else
        @featured_collections = organization.collections.public_collections.order_feature_name
      end
    else
      @featured_collections = Collection.is_featured.sample(8)
    end
    partial_name = 'home/collections_home'
    partial_name = 'home/collections_home_inner' if organization.present?
    render json: { partial: render_to_string(partial: partial_name, locals: { featured_collections: @featured_collections }) }
  end

  def featured_playlists
    organization = current_organization
    if organization
      if current_user.present?
        user_current_organization = current_user.organization_users.active.where(organization_id: organization.id)
        @featured_playlists = if user_current_organization.present?
                                Playlist.where(organization: organization).order_feature_name
                              else
                                organization.playlists.public_playlists.order_feature_name
                              end
      else
        @featured_playlists = organization.playlists.public_playlists.order_feature_name
      end
    else
      @featured_playlists = Playlist.is_featured.sample(8)
    end
    render json: { partial: render_to_string(partial: 'home/playlists_home_inner', locals: { featured_playlists: @featured_playlists }) }
  end

  def featured_resources
    organization = current_organization
    resource_where = query_conditions
    @collection_wise_resources = []
    if organization.present?
      @collection_wise_resources = organization.collections.joins(:collection_resources).where(resource_where).order('is_featured desc').group('id')
    end
    @featured_resources = CollectionResource.list_resources(organization, nil, resource_where, true, 8)
    partial_name = 'home/resources_home'
    partial_name = 'home/resources_home_inner' if organization.present?
    render json: { partial: render_to_string(partial: partial_name, locals: { featured_resources: @featured_resources, collection_wise_resources: @collection_wise_resources, featured: true }) }
  end

  def collection_wise_resources
    organization = current_organization
    resource_where = query_conditions
    @collection = Collection.find(params[:id])
    @collection_wise_resources = []
    @collection_wise_resources << { resources: CollectionResource.list_resources(organization, @collection.id, resource_where, false, 8) }
    partial_name = 'home/collectionwise_resources'
    render json: { partial: render_to_string(partial: partial_name, locals: { collection: @collection, collection_wise_resources: @collection_wise_resources, featured: true }) }
  end

  def query_conditions
    organization = current_organization
    access_filter = [CollectionResource.accesses[:access_public]]
    access_filter << CollectionResource.accesses[:access_restricted] if current_user.present? && organization.present?
    collection_access = 'collections.is_public IN (1)'
    if current_user.present? && organization.present? && current_user.organization_users.active.where(organization_id: organization.id).present?
      collection_access = 'collections.is_public IN (1,0)'
      access_filter << CollectionResource.accesses[:access_private]
      resource_where = "(collection_resources.access IN(#{access_filter.join(', ')}) AND #{collection_access})"
      return resource_where
    end
    is_allowed = "(collection_resources.access IN(#{access_filter.join(', ')}) AND #{collection_access})"
    is_allowed.to_s
  end

  def featured_organization
    unless current_organization
      @featured_organizations = Organization.active_orgs.sample(8)
    end

    render json: { partial: render_to_string(partial: 'home/featured_organizations_home', locals: { featured_organizations: @featured_organizations }) }
  end

  def set_layout
    session[:layout] = params[:layout]
    render json: { status: 'success' }
  end

  def noid
    collection_resource = CollectionResource.find_by_noid!(params[:noid])
    session[:share] = params[:share] if params[:share].present?
    if params[:media].present?
      redirect_to collection_collection_resource_details_path(collection_resource.collection, collection_resource, params[:media], t: params[:t], share: params[:share])
    else
      redirect_to collection_collection_resource_path(collection_resource.collection, collection_resource, t: params[:t], share: params[:share])
    end
  rescue StandardError
    flash[:notice] = 'No Collection Resource found.'
    redirect_to request.url.gsub(request.path, '')
  end

  def playlist_share
    playlist_id = Base64.urlsafe_decode64(params[:encoded_id]).gsub('share', '')
    playlist = Playlist.find_by_id!(playlist_id)
    session[:share] = params[:share] if params[:share].present?
    redirect_to playlist_show_path(playlist, share: params[:share])
  rescue StandardError
    flash[:error] = 'Not a valid playlist url'
    redirect_to root_path
  end

  def resource_unique_identifier
    sequential_number_of_media_file, seconds_to_start_time, collection_resource = HomePresenter.unique_identifier_param_manager(params, current_organization)
    return redirect_to not_found_url(subdomain: false) if collection_resource.blank? || collection_resource.collection.organization.custom_url_for_resource.blank?
    collection_resource_file = if sequential_number_of_media_file.present?
                                 offset = sequential_number_of_media_file.present? && sequential_number_of_media_file.to_i > 0 ? sequential_number_of_media_file.to_i - 1 : 0
                                 collection_resource.collection_resource_files.order(:sort_order).limit(1).offset(offset).present? ? collection_resource.collection_resource_files.order(:sort_order).limit(1).offset(offset).first : nil
                               end
    url_params = if seconds_to_start_time.present? && collection_resource_file.present?
                   { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id, resource_file_id: collection_resource_file.id,
                     t: seconds_to_start_time, host: Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization) }
                 elsif collection_resource_file.present? && sequential_number_of_media_file.present?
                   { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id, resource_file_id: collection_resource_file.id,
                     host: Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization) }
                 else
                   { collection_id: collection_resource.collection.id, collection_resource_id: collection_resource.id,
                     host: Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization) }
                 end
    url_params[:embed] = 'true' if (params[:embed].present? && params[:embed] == 'true') || request.url.include?('/embed/')
    return redirect_to collection_collection_resource_details_url(url_params)
  rescue StandardError
    return redirect_to not_found_url(subdomain: false)
  end

  def media
    resource_file = CollectionResourceFile.find_by_id!(Base64.decode64(params[:id]))
    tracking_param = JSON.parse(params.to_json)
    tracking_param['target_id'] = Base64.decode64(params[:id])
    tracking_param['organization_id'] = current_organization.id
    tracking_param['user_type'] = Role.all_user_types[4]
    ahoy.track('podcast', tracking_param)
    redirect_to resource_file.resource_file.url
  end

  def forbidden; end

  def not_found; end

  def terms_of_service; end

  def privacy_policy; end

  def about; end

  def features; end

  def contact_us
    @support_request = SupportRequest.new
  end

  def support
    @support_request = SupportRequest.new
  end

  def submit_request
    @support_request = SupportRequest.new(support_request_params)
    if @support_request.valid?
      @support_request.save
      UserMailer.support_request_received(@support_request).deliver_now
      flash[:notice] = 'Thanks for contacting us! We will get in touch with you shortly.'
      redirect_to root_url
    else
      render @support_request.request_type
    end
  end

  def download_media
    file = CollectionResourceFile.find(params[:id])
    if file.embed_type.present? || !file.is_downloadable || !permission_to_access_file?(file)
      return redirect_to collection_collection_resource_url(file.collection_resource.collection, file.collection_resource), notice: 'Either File is not downloadable or you don\'t have access to file'
    end
    expiry = file.duration.to_f * 2
    path = file.resource_file.expiring_url(expiry.ceil)
    content_type = file.resource_file_content_type
    content_type = 'video/mp4' if file.resource_file_content_type == 'video/quicktime'
    url = URI.parse(path)
    unless url.host.present?
      url = request.base_url + path
    end
    data = open(url.to_s)
    send_data data.read, type: content_type, filename: file.resource_file_file_name, disposition: 'attachment'
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def support_request_params
    params.require(:support_request).permit(:name, :organization, :email, :message, :request_type)
  end
end
