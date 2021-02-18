# controllers/public_access_url_controller.rb
#
# PublicAccessUrlController
# The class is responsible for managing the organization public accesses
#
# Author::    Furqan Wasi  (mailto:furqan@weareavp.com)
class PublicAccessUrlsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize! :manage, current_organization
    if request.xhr?
      render json: PublicAccessUrlDatatable.new(view_context, current_organization)
    else
      render 'public_access_urls/public_access_urls'
    end
  end

  def edit
    @public_access_url = PublicAccessUrl.find_by_id(params[:id])
    @type = params[:type]
    render partial: 'public_access_urls/form'
  end

  def update_info
    authorize! :manage, current_organization
    flag = false
    msg = t('error_update')
    public_access_url = PublicAccessUrl.find_by_id(params[:id])
    if public_access_url.present?
      if params['action_type'] == 'updateStatus' && public_access_url.update(status: params[:status].to_s.to_boolean?)
        msg = ' Access ' + t('status_successfully_updated')
        flag = true
      elsif params['action_type'] == 'delete_access' && public_access_url.destroy
        msg = ' Access ' + t('delete_success')
        flag = true
      end
    end

    if request.xhr?
      render json: { msg: msg, status: flag }
    else
      type = flag ? :notice : :error
      flash[type] = msg
      redirect_to public_access_urls_path
    end
  end
end
