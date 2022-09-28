# Role
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  def self.organization_role_ids
    where(system_name: %w'organization_admin organization_owner organization_user').map(&:id)
  end

  def self.all_user_types
    %w[organization_admin organization_user organization_owner registered_user public_user]
  end

  def self.org_owner_id
    where(system_name: %w'organization_owner').map(&:id)
  end

  def self.org_admin_id
    where(system_name: %w'organization_admin').map(&:id)
  end

  def self.org_owner_and_admin_id
    where(system_name: %w'organization_owner organization_admin').map(&:id)
  end

  def self.organization_roles
    where(system_name: %w'organization_admin organization_owner organization_user ohms_assigned_user')
  end

  def self.role_organization_owner
    find_by(system_name: 'organization_owner')
  end

  def self.organization_admin_or_user
    where(system_name: %w'organization_admin organization_user').map(&:id)
  end

  def self.organization_ohms_assigned_user
    where(system_name: %w'ohms_assigned_user').map(&:id)
  end
end
