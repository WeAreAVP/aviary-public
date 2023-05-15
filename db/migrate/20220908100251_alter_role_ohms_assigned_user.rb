class AlterRoleOhmsAssignedUser < ActiveRecord::Migration[6.1]
  def change
    Role::where(system_name: 'ohms_assigned_user').where(name: 'OHMS Assigned User').first_or_create
  end
end
