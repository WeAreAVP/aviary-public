# Model of SupportRequest
# models/support_request.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SupportRequest < ApplicationRecord
  enum request_type: { contact_us: 0, support: 1 }
  validates :email, :name, :request_type, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
