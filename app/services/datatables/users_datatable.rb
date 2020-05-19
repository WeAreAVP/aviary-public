# UsersDatatable
class UsersDatatable < ApplicationDatatable
  delegate :edit_admin_user_path, :options_for_select, :select_tag, :content_tag,
           :user_change_org_status_path, :user_remove_user_path, to: :@view
  attr_accessor :current_user_details

  def initialize(view, current_resource, current_organization = nil)
    @view = view
    @current_resource = current_resource
    @current_organization = current_organization
  end

  private

  def data
    all_users, users_count = users
    users_data = all_users.map do |user|
      [].tap do |column|
        column << user.email
        column << user.first_name + ' ' + user.last_name
        column << (user.organization_id.present? ? user_role(user) : '')
        column << (user.organization_id.present? ? organization_status(user) : '')
        column << links(user)
      end
    end
    [users_data, users_count]
  end

  def count; end

  def users
    @users ||= fetch_users
  end

  def fetch_users
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end

    User.fetch_user_list(@current_resource, page, per_page, sort_column, sort_direction, params, @current_organization)
  end

  def user_role(user)
    return '&nbsp;' + user.role_name if @current_resource == user || (@current_resource.current_org_admin(@current_organization).present? && user.current_org_owner(@current_organization).present?)
    select_tag 'roles', options_for_select(Role.organization_roles.collect { |u| [u.name, u.id] }, selected: user.role_id),
               class: 'user_org_role', disabled: @current_resource == user,
               data: { user_id: user.id, organization_id: user.organization_id, role_id: user.role_id,
                       path: user_change_org_status_path(user) }
  end

  def organization_status(user)
    return user.org_status ? '&nbsp;Active' : '&nbsp;Inactive' if @current_resource == user || (@current_resource.current_org_admin(@current_organization).present? && user.current_org_owner(@current_organization).present?)
    content_tag(:label, '', class: 'toggle-switch org_status_cus') do
      content_tag(:input, nil, type: 'checkbox', checked: user.org_status?, disabled: @current_resource == user, class: 'toggle-switch__input',
                               data: { user_id: user.id, organization_id: user.organization_id, role_id: user.role_id, path: user_change_org_status_path(user) }) +
        content_tag(:span, '', class: 'toggle-switch__slider')
    end
  end

  def links(user)
    if @current_resource.is_a?(Admin)
      link_to('Delete', user_remove_user_path(user, user.organization_id), class: 'btn-sm btn-danger remove-user-organization-popup') if user.organization_id.present?
    elsif @current_organization && @current_organization.current_user_org_owner(@current_resource).present? && @current_resource.id != user.id
      link_to('Delete', user_remove_user_path(user, @current_organization), class: 'btn-sm btn-danger remove-user-organization-popup')
    end
  end

  def columns
    %w(email first_name roles_org.name om.status)
  end
end
