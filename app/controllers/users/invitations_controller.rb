# Users::InvitationsController
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Users::InvitationsController < Devise::InvitationsController
  private

  def update_resource_params
    params.require(:user).permit(:first_name, :last_name, :preferred_language, :agreement, :status, :password, :password_confirmation, :invitation_token)
  end
end
