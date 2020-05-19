# Users::InvitationsController
class Users::InvitationsController < Devise::InvitationsController
  private

  def update_resource_params
    params.require(:user).permit(:first_name, :last_name, :preferred_language, :agreement, :status, :password, :password_confirmation, :invitation_token)
  end
end
