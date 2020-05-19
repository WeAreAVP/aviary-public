# Model of SupportRequest
# models/support_request.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class SupportRequest < ApplicationRecord
  enum request_type: { contact_us: 0, support: 1 }
  validates :email, :name, :request_type, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
