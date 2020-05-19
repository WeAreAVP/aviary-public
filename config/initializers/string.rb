# add String tags to String
class String
  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def to_boolean?
    ActiveModel::Type::Boolean.new.cast(self.to_s.downcase)
  end
end