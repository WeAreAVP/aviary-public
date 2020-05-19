# CommonHelper
module CommonHelper
  def search_int_value(array, key, value)
    array.index { |hash| hash[key].to_i == value.to_i } unless array.nil?
  end

  def search_string_value(array, key, value)
    array.index { |hash| hash[key].to_s == value.to_s } unless array.nil?
  end
end
