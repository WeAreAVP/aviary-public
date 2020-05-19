# OrganizationMailer
class OrganizationMailer < ApplicationMailer
  def inactive_after_month(owner, organization)
    @organization = organization
    @user = owner
    mail(to: @user.email, subject: 'Aviary - account cancellation notification')
  end
end
