class String
  alias :each :each_char
  def is_i?
    self.to_i.to_s == self
  end
end
