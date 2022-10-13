# UsersController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class UsersController < ApplicationController
  respond_to :js
  include ApplicationHelper
  before_action :authenticate_user!, :permissions?

  def change_org_status
    user = User.find_by_id(params[:user_id])
    organization = Organization.find_by_id(params[:org_id])

    organization_user = organization.organization_users.where(user_id: user.id).first

    if organization_user.present?
      if params[:role_id].present?
        organization_user.update(role_id: params[:role_id])
      end
      if params[:status].present?
        organization_user.update(status: params[:status])
      end

      message = t('user_status_updated')
      response = 1
    else
      message = t('error_update_user')
      response = 0
    end

    respond_to do |format|
      format.json { render json: [response: response, notice: message], status: :accepted }
    end
  end

  # GET /admin/users
  # GET /admin/users.json
  def index
    @roles = Role.organization_roles
    existing_organizations = current_user.organization_users.map(&:organization_id)
    @user_organizations = Organization.where(id: existing_organizations)

    @member_invites = current_organization.organization_users.joins(:user).merge(User.invitation_not_accepted)
    @member_invites += current_organization.organization_users.where.not(token: nil)
    respond_to do |format|
      format.html
      format.json { render json: UsersDatatable.new(view_context, current_user, current_organization) }
    end
  end

  # GET /admin/users/1
  # GET /admin/users/1.json
  def show; end

  # GET /admin/users/new
  def new; end

  # GET /admin/users/1/edit
  def edit; end

  def add_new_member
    organization = Organization.find_by_id(current_organization.id)
    add_users = params[:user]
    hash = { messages: [], already_member: [], invitation_sent: [], user_successfully_added: [] }
    add_users.each do |user_email|
      search = user_email['search']
      user_role = user_email['user_role']
      user = User.where(email: search).first

      unless user.present?
        invited_user = User.invite!(email: search, username: search, created_by_id: current_user.id, updated_by_id: current_user.id) do |u|
          u.skip_invitation = true
        end
        if user_role.to_i == 4
          UserMailer.ohms_invite_message(invited_user, organization).deliver_now
        else
          UserMailer.invite_message(invited_user, organization).deliver_now
        end
        organization.organization_users.create(user_id: invited_user.id, role_id: user_role)
        hash[:invitation_sent] << search
        next
      end

      organization_member = organization.organization_users.where(user_id: user.id).first

      if organization_member.present?
        hash[:already_member] << search
        next
      end
      token = Devise.friendly_token
      organization.organization_users.create(user_id: user.id, role_id: user_role, status: false, token: token)
      UserMailer.join_organization(user, organization, token).deliver_now
      hash[:user_successfully_added] << search
    end
    hash[:messages] << { user: hash[:invitation_sent], message: t('invitation_sent'), atype: 'success' }
    hash[:messages] << { user: hash[:already_member], message: t('already_member'), atype: 'error' }
    hash[:messages] << { user: hash[:user_successfully_added], message: t('user_successfully_added'), atype: 'success' }
    render json: { message: hash[:messages], status: 'success' }
  end

  def add_member_row
    @roles = Role.organization_roles
    partial_name = 'users/add_member_row'
    render json: { partial: render_to_string(partial: partial_name, locals: { roles: @roles }) }
  end

  # POST /admin/users
  # POST /admin/users.json
  def create; end

  # PATCH/PUT /admin/users/1
  # PATCH/PUT /admin/users/1.json
  def update; end

  # DELETE /admin/users/1
  # DELETE /admin/users/1.json
  def destroy
    org_user = current_organization.organization_users.where(user_id: params[:id]).first
    org_user.user.confirmed? ? org_user.delete : org_user.user.destroy

    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User deleted successfully.' }
      format.json { head :no_content }
    end
  end

  def remove_user
    OrganizationUser.where(user_id: params[:user_id], organization_id: params[:organization_id]).delete_all
    respond_to do |format|
      format.html { redirect_to users_path, notice: 'User successfully removed.' }
      format.json { head :no_content }
    end
  end

  def permissions?
    redirect_to forbidden_url unless current_user_is_org_owner_or_admin?
  end
end
