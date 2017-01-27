class Location < ApplicationModel
  belongs_to :promotion
  belongs_to :parent_location, :class_name=>'Location'
  has_many :locations, :class_name=>'Location', :foreign_key=>'parent_location_id', :order=>'sequence ASC, name ASC'
  has_many :contents, :class_name=>'LocationContent', :order=>'sequence', :conditions=>'name is null'
  has_many :truncated_contents, :class_name=>'LocationContent', :order=>'sequence', :conditions=>'name is not null'
  attr_accessible :promotion_id, :name, :sequence, :root_location_id, :parent_location_id, :depth, :created_at, :updated_at, :logo, :content, :has_content
  attr_privacy :promotion_id, :name, :sequence, :root_location_id, :parent_location_id, :depth, :created_at, :updated_at, :logo, :public
  attr_privacy_no_path_to_user

  has_many :users, :conditions => proc { "users.location_id = #{self.id} OR users.location_id IN (SELECT id FROM locations WHERE parent_location_id = #{self.id})" }

  flags :has_content

  before_save :set_root_location
  before_save :set_sequence

  validates_presence_of :name

  after_create :clear_cache
  after_update :clear_cache

  mount_uploader :logo, LocationLogoUploader

  has_one :resource

  scope :top, lambda { where("parent_location_id IS NULL")}

  def depth
    d=0
    unless new_record?
      s=self
      p=s.parent_location
      while p
        d+=1
        p=p.parent_location
      end
    else
      d = parent_location ? parent_location.depth+1 : 0
    end
    d
  end

  def set_root_location
    self.root_location_id = self.top_location
  end

  def set_sequence
    self.sequence ||= self.top? ? self.promotion.locations.top.maximum('sequence').to_i + 1 : self.parent_location.locations.maximum('sequence').to_i + 1 
  end

  def top_location(this_location = self, i = 0)
    return Location.find(self.root_location_id) if self.root_location_id
    return this_location if !this_location.parent_location || i > 20 # just in case the data gets effed we can break out of an infinite loop..
    return self.top_location(this_location.parent_location, i += 1)
  end

  def top?
    parent_location_id.nil?
  end

  def new_user_registration(user,reload_after=false)
    if user.trip.total_days > 0 && user.trip.profile.started_on <= user.promotion.current_date
      puts "incrementing region's total days by #{user.trip.total_days} to reflect newly registered user"
      connection.execute "update locations set total_participants=total_participants+1, total_days = total_days + #{user.trip.total_days} where id = #{self.id}"
      self.reload if reload_after
    else
      puts "not incrementing region's total days, user starts in future"
    end
  end

  def user_deleted(user)
    begin
      puts "decrementing region's total days because user was destroyed"
      # first try to figure out if we need to decrement based on the user's start date (if the user wasn't eager loaded, then we won't be able to retrieve this info)
      if user.trip.total_days > 0 && user.trip.profile.started_on <= user.promotion.current_date
        mins = user.trip.entries.collect{|e|e.logged_on <= user.promotion.current_date ? e.exercise_minutes : 0}
        goals = mins.select{|i|i>=user.promotion.minimum_minutes_low}.size
        connection.execute "
          update locations set
             total_participants = total_participants -1
            ,total_days = total_days - #{user.trip.total_days}
            ,total_exercise = total_exercise - #{mins.sum}
            ,total_goals_earned = total_goals_earned - #{goals}
          where id = #{self.id}
        "
      end
    rescue
      # if we can't decrement it by using the code above, we'll do it the hard way and hit the stats table
      set_stats
    end
  end

  def set_stats
    puts "setting stats for #{self.name}"
    connection.execute "
      update locations
      left join (
       select
          top_level_location_id
         ,count(distinct user_id) total_participants
         ,count(1) total_days
       from stats
       where top_level_location_id = #{self.id} and reported_on between started_on and '#{promotion.current_date.strftime('%Y-%m-%d')}'
       group by top_level_location_id
       ) stats on stats.top_level_location_id = locations.id
      set
         locations.total_participants = coalesce(stats.total_participants,0)
        ,locations.total_days = coalesce(stats.total_days,0)
      where locations.id = #{self.id}
    "
    reload
  end

  def bottom_level_locations
    bottom_locations = []
    locations.each do |l|
      bottom_locations << (l.locations.empty? ? l : l.locations)  #only works if there are 3 or less levels
    end
    bottom_locations.flatten
  end

  def children
    return Location.where(:parent_location_id => self.id)
  end

  def clear_cache
    cache_key = "promotion_#{self.promotion_id}_nested_locations"
    Rails.cache.delete(cache_key)
  end

end
