# add String tags to String
class String
  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def to_boolean?
    ActiveModel::Type::Boolean.new.cast(self.to_s.downcase)
  end

  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end

  def match_all(regex, value_for_occurrences = 1)
    prev_offset = -1
    offset = 0
    matches = {}
    while (prev_offset < offset) && (z = self[offset..-1].match(/#{regex}/i))
      matches[z.offset(0).collect {|x| x + offset }.second] = value_for_occurrences
      prev_offset = offset
      offset = z.offset(0)[1] + offset
    end
    matches
  end

  def to_filename
    filename = self.gsub(/\s|"|'/, '')
    filename.gsub(/[^0-9A-Za-z_.]/, '')
  end
end