# add Hash tags to Hash
class Hash
  
  def without(*keys)
    dup.without!(*keys)
  end

  def without!(*keys)
    reject! { |key| keys.include?(key) }
  end
end