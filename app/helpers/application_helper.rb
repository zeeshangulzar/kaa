module ApplicationHelper
  def self.is_i?(x = nil)
    return false if x.nil?
    if x.class == String
      return x.is_i?
    elsif x.respond_to('integer?')
      return x.integer?
    else
      return x.to_s.is_i?
    end
  end
end
