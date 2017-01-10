module ApplicationHelper

  def self.is_i?(x = nil)
    return false if x.nil?
    if x.class == String
      return x.is_i?
    elsif x.respond_to?('integer?')
      return x.integer?
    else
      return x.to_s.is_i?
    end
  end

  def self.seconds_to_midnight(promotion = nil)
    if promotion.nil?
      seconds = (Date.today + 1).to_time.to_i - Time.now.to_i
    else
      seconds = (promotion.current_date + 1).to_time.to_i - promotion.current_time.to_i
    end
    return seconds
  end

end
