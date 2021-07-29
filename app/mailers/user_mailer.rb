# UserMailer
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class UserMailer < ApplicationMailer
  def new_organization_email(organization)
    @organization = organization
    @user = @organization.user
    mail(to: @organization.user.email, subject: 'A new Aviary organization account has been assigned to you!')
  end

  def support_request_received(support_request)
    @support_request = support_request
    mail(to: ENV['SUPPORT_EMAIL'], subject: "Aviary - #{support_request.request_type} Request")
  end

  def invite_message(user, organization)
    @user = user
    @organization = organization
    @token = user.raw_invitation_token
    @invitation_link = accept_user_invitation_url(invitation_token: @token)
    mail(to: @user.email, subject: "#{@organization.name} has invited you to join Aviary!")
  end

  def admin_invite_message(user)
    @user = user
    @token = user.confirmation_token
    @confirmation_link = user_confirmation_url(confirmation_token: @token)
    mail(to: @user.email, subject: 'Your invitation to join Aviary')
  end

  def join_organization(user, organization, token)
    @user = user
    @organization = organization
    @confirmation_link = org_confirm_invite_url(token: token)
    mail(to: user.email, subject: 'Aviary confirmation')
  end

  def ohms_xsd_changed
    team_list = 'furqan@weareavp.com,nouman@weareavp.com,bertram@weareavp.com'
    mail(to: team_list, subject: 'Update in OHMS XSD')
  end
end
