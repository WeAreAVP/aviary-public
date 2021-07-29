# UserDecorator
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class UserDecorator < Draper::Decorator
  delegate_all

  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end
end
