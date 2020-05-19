# Application Module
class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: "AVIARY <#{ENV['FROM_EMAIL']}>"
  layout 'mailer'
end
