# OrganizationUser
class OrganizationUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  belongs_to :role
  scope :owner_or_admin, -> { where(role_id: Role.org_owner_and_admin_id) }
  scope :owner, -> { where(role_id: Role.org_owner_id) }
  scope :admin, -> { where(role_id: Role.org_admin_id) }
  scope :active, -> { where(status: true) }
end
