# ApplicationHelperExtended
module ApplicationHelperExtended
  def role_type(user, organization)
    role_name = Role.all_user_types[4]
    if user.present?
      if user.organization_users.present? && organization.present?
        role_user = user.organization_users.where(organization_id: organization.id)
        role_name = if role_user.present? && role_user.first.role.present?
                      role_user.first.role.system_name
                    else
                      Role.all_user_types[3]
                    end
      else
        role_name = Role.all_user_types[3]
      end
    end
    role_name
  end
end
