# Application Module
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: "AVIARY <#{ENV.fetch('FROM_EMAIL', nil)}>"
  layout 'mailer'
end
