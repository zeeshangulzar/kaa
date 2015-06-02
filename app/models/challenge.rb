class Challenge < ApplicationModel
  self.inheritance_column = 'column_that_is_not_type'
  attr_privacy :promotion_id, :name, :description, :type, :location_id, :location, :visible_from, :visible_to, :creator, :image, :status, :category, :expires_on, :any_user
  attr_privacy_no_path_to_user
  attr_accessible *column_names
  
  belongs_to :promotion
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :location, :in_json => true

  has_many :challenges_sent, :class_name => "ChallengeSent"
  has_many :challenges_received, :class_name => "ChallengeReceived"
  
  TYPE = {
    :peer     => 'peer',
    :regional => 'regional'
  }

  TYPE.each_pair do |key, value|
    self.send(:scope, key, where(:type => value))
  end

  TYPE.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.type == value })
  end
  
  STATUS = {
    :deleted  => 0,
    :inactive => 1,
    :active   => 2
  }

  STATUS.each_pair do |key, value|
    self.send(:scope, key, where(:status => value))
  end

  STATUS.each_pair do |key, value|
    self.send(:define_method, "#{key}?", Proc.new { self.status == value })
  end

  # Define scopes for prompt type
  scope :visible, lambda{|promotion|
    where("(visible_from <= ? OR visible_from IS NULL) AND (visible_to >= ? OR visible_to IS NULL) AND (expires_on <= ? OR expires_on IS NULL)", promotion.current_date, promotion.current_date, promotion.current_date)
  }

  # Define scopes for prompt type
  scope :not_deleted, where("status <> ?", Challenge::STATUS[:deleted])

  mount_uploader :image, ChallengeImageUploader

  def is_visible?
    return (!self.visible_from || self.visible_from <= self.promotion.current_date) && (!self.visible_to || self.visible_to >= self.promotion.current_date)
  end

  def self.active_peer(promotion)
    challenges = promotion.challenges.peer.active.where("expires_on >= ? OR expires_on IS NULL", promotion.current_date)
    if challenges.size < 10 && promotion.challenges.peer.active.count >= 10
      # only try to activate stuff if enough challenges exist to match minimum # (hard-coded @ 10)
      all_categories = promotion.challenges.peer.active.group(:category).order("count_category DESC").count(:category)
      active_categories = challenges.group(:category).order("count_category ASC").count(:category)
      x = 10 - challenges.size
      x.times do
        category = all_categories.first
        all_categories.each{ |cat, cat_count|
          if active_categories[cat].nil? || (active_categories[cat] && active_categories[cat] == active_categories.collect{|k,v|v}.min && active_categories[cat] < cat_count)
            category = cat
          end
        }
        c = promotion.challenges.peer.active.where("expires_on < ? AND category = ?", promotion.current_date, category).order("expires_on ASC").first
        if c
          c.update_attributes(:expires_on => promotion.current_date + 14)
          challenges << c
          active_categories[category] = active_categories[category] + 1 rescue 1
        end
      end
    end
    return challenges
  end

end
