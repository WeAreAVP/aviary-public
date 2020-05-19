# UserDecorator
class UserDecorator < Draper::Decorator
  delegate_all

  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end
end
