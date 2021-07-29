# OrganizationMailer
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OrganizationMailer < ApplicationMailer
  def inactive_after_month(owner, organization)
    @organization = organization
    @user = owner
    mail(to: @user.email, subject: 'Aviary - account cancellation notification')
  end
end
