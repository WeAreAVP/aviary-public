# Admin::UsersDatatable
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::Admin::UsersDatatable < Datatables::ApplicationDatatable
  delegate :edit_admin_user_path, :admin_user_path, to: :@view
  def initialize(view)
    @view = view
  end

  private

  def data
    all_users, users_count = users
    users_data = all_users.map do |user|
      [].tap do |column|
        name = user.first_name + ' ' + user.last_name
        column << user.email
        column << name
        links = '<a href="' + edit_admin_user_path(user) +
                '"class="btn-sm btn-success">Edit</a>&nbsp;&nbsp;'
        links += '<a href="javascript://" class="btn-sm btn-danger admin_user_delete" data-url="' + admin_user_path(user) + '" data-name="' + name + '">Delete</a>'
        column << links
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
    User.admin_user_list(page, per_page, sort_column, sort_direction, params)
  end

  def columns
    %w(email first_name last_name)
  end
end
