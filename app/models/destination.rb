class Destination < ApplicationModel
  attr_privacy :id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :sequence, :map_id, :quote_text, :quote_name, :quote_image, :quote_caption, :images, :icon1_mobile, :icon2_mobile, :any_user
  attr_privacy :image1, :image1_caption, :image2, :image2_caption, :image3, :image3_caption, :image4, :image4_caption, :image5, :image5_caption, :master
  attr_privacy_no_path_to_user
  attr_accessible :map_id, :name, :icon1, :icon2, :content, :blurb, :question, :answers, :correct_answer, :status, :sequence, :created_at, :quote_text, :quote_name, :quote_image, :quote_caption, :image1, :image1_caption, :image2, :image2_caption, :image3, :image3_caption, :image4, :image4_caption, :image5, :image5_caption, :updated_at, :icon1_mobile, :icon2_mobile

  belongs_to :map

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

  def images
    arr = []
    (1..5).each{|i|
      arr << {:image => self.send("image#{i}"), :caption => self.send("image#{i}_caption")} if !self.send("image#{i}").nil?
    }
    return arr
  end

  # TODO: this is presently returning JSON, needs to return objects
  # need to convert destinations to hashes or otherwise affix is_earned, etc.
  # attach only works when it converts to json, hence the present state..
  def self.user_destinations(user_or_id, destination_id = nil)
    user = user_or_id.is_a?(Integer) ? User.find(user_or_id) : user_or_id
    promotion = user.promotion
    destination_ids = Route.ordered_destination_ids(promotion.route)
    
    #include the current day
    days = [(promotion.current_date - promotion.starts_on + 1), promotion.route.length].min

    return [] if days < 0
    
    destination_ids = destination_ids.slice(0, days)

    user_destinations = []
    destinations = Destination.find(destination_ids).index_by(&:id).to_h
    user_answers = user.user_answers.index_by(&:destination_id).to_h


    entries = Hash[*user.entries.available({:start => promotion.starts_on, :end => promotion.current_date}).map{|entry| [entry.recorded_on.to_s(:db), {:id => entry.id, :is_recorded => entry.is_recorded}]}.flatten]

    (promotion.starts_on..promotion.current_date).take(destination_ids.length).each_with_index{ |date, i|
      day = i + 1
      date = date.to_s(:db)
      destination = destinations[destination_ids[i]]
      destination.attach({
        :day          => day,
        :date         => date,
        :entry_id     => entries.key?(date) ? entries[date][:id] : nil,
        :is_earned    => entries.key?(date) ? entries[date][:is_recorded] : nil,
        :images       => destination.images
      })
      if user_answers.key?(destination.id)
        destination.attach({
          :correct_answer    => destination.correct_answer,
          :user_quiz_correct => user_answers[destination.id][:is_correct],
          :user_quiz_answer  => user_answers[destination.id][:answer]
        })
      end
      if !destination_id.nil? && destination.id == destination_id
        # returns a single user destination
        return destination
      end
      user_destinations << destination
    }
    return user_destinations
  end

  def answers
    return read_attribute(:answers).split(/\n+/).select(&:present?)
  end

  def check_answer(submission)
    return false if self.correct_answer.nil?
    return submission.strip.downcase == self.correct_answer.strip.downcase
  end
  
end