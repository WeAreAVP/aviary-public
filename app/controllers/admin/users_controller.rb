# Admin::UsersController
#
# This controller is responsibe for managing the users by the Aviary admin
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Admin::UsersController < AdminController
  before_action :set_user, except: :index

  def index
    respond_to do |format|
      format.html
      format.json { render json: Admin::UsersDatatable.new(view_context) }
    end
  end

  def pending
    @pending_users = User.invitation_not_accepted
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(admin_user_params)
    @user.agreement = true
    @user.skip_confirmation_notification!
    if @user.save
      UserMailer.admin_invite_message(@user).deliver_now
      redirect_to admin_users_url, notice: 'User added successfully.'
    else
      render 'new'
    end
  end

  def edit
    existing_organizations = @user.organization_users.map(&:organization_id)
    @organizations = Organization.where.not(id: existing_organizations)
  end

  def update
    result = admin_user_params['password'].present? ? @user.update(admin_user_params) : @user.update_without_password(admin_user_params)
    if result
      redirect_to admin_users_url, notice: 'User updated successfully.'
    else
      render 'edit'
    end
  end

  def organization_create
    @user.organization_users.create(organization_id: params[:organization_id], role_id: params[:role_id])
  end

  def organization_update
    organization_user = @user.organization_users.where(organization_id: params[:organization_id]).first
    organization_user.update(role_id: params[:role_id], status: params[:status])

    respond_to do |format|
      format.json { render json: [notice: ''], status: :accepted }
    end
  end

  def organization_destory
    assocication = @user.organization_users.find(params[:org_user_id])
    is_admin_or_user = Role.organization_admin_or_user.include? assocication.role_id
    current_owners = OrganizationUser.where(organization_id: assocication.organization_id).owner
    if current_owners.size > 1 || is_admin_or_user
      assocication.delete
      flash[:notice] = 'Organization association deleted successfully.'
    else
      flash[:notice] = 'Operation not permitted, an Organization Owner cannot be deleted. In order to delete this user you must delete the organization first.'
    end

    redirect_back(fallback_location: root_path)
  end

  def destroy
    @user.destroy
    redirect = params[:pending] ? pending_admin_users_url : admin_users_url
    redirect_to redirect, notice: 'User deleted successfully.'
  end

  def set_user
    id = params[:user_id].present? ? params[:user_id] : params[:id]
    @user = User.find_by_id(id)
  end

  def export
    @users = User.admin_user_list_export
    csv_rows = []
    csv_rows << ['ID', 'Full Name', 'Email', 'Organization', 'Role']
    @users.each do |usr|
      row = [usr.id, usr.first_name + ' ' + usr.last_name, usr.email, usr.organization, usr.role]
      csv_rows << row
    end
    users_csv = CSV.generate(headers: true) do |csv|
      csv_rows.map { |row| csv << row }
    end
    send_data users_csv, filename: "Users_#{Date.today}.csv", type: 'csv'
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def admin_user_params
    params.require(:user).permit(:id, :first_name, :last_name, :agreement, :photo, :preferred_language, :username,
                                 :password, :password_confirmation, :receive_emails, :email)
  end
end
