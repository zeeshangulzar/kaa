# i want is_i? available everywhere!
class Object
  # to_i isn't a method for some objects, so return false unless overridden
  def to_i
    return false
  end
  def is_i?
    self.to_i.to_s == self.to_s
  end
end