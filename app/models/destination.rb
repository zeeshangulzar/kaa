class Destination < ApplicationModel
  attr_privacy :id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :sequence, :map_id, :any_user
  attr_privacy_no_path_to_user
  attr_accessible :map_id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :correct_answer, :status, :sequence, :created_at, :updated_at

  belongs_to :map

  mount_uploader :icon1, DestinationIcon1Uploader
  mount_uploader :icon2, DestinationIcon2Uploader

  has_photos # TODO: temporary?

  # TODO: do these make sense?
  STATUS = {
    :active   => 'active',
    :deleted  => 'deleted'
  }
  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end
  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  def destroy
    # TODO: we want to do a soft delete, so figure out what this should do...
    self.status = STATUS[:deleted]
    self.save!
  end

  # TODO: this is presently returning JSON, needs to return objects
  # need to convert destinations to hashes or otherwise affix is_earned, etc.
  # attach only works when it converts to json, hence the present state..
  def self.user_destinations(user_or_id)
    user = user_or_id.is_a?(Integer) ? User.find(user_or_id) : user_or_id
    promotion = user.promotion
    destination_ids = Route.ordered_destination_ids(promotion.route)
    
    days = promotion.current_date - promotion.starts_on

    return [] if days < 0
    
    destination_ids = destination_ids.slice(0, days + 1)

    user_destinations = []
    destinations = Destination.find(destination_ids).index_by(&:id).to_h


    entries = Hash[*user.entries.available({:start => promotion.starts_on, :end => promotion.current_date}).map{|entry| [entry.recorded_on.to_s(:db), {:id => entry.id, :is_recorded => entry.is_recorded}]}.flatten]

    (promotion.starts_on..promotion.current_date).take(destination_ids.length).each_with_index{ |date, i|
      day = i + 1
      date = date.to_s(:db)
      destination = destinations[destination_ids[i]]
      destination.attach({
        :day => day,
        :date => date,
        :entry_id => entries.key?(date) ? entries[date][:id] : nil,
        :is_earned => entries.key?(date) ? entries[date][:is_recorded] : nil
      })
      user_destinations << destination
    }
    return user_destinations
  end
  
end