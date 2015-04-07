require 'bcrypt'

class User < ApplicationModel
  include KpwalkUserAdditions
  include HESFitbitUserAdditions
  include HESJawboneUserAdditions
  include PerModelEncryption

  flags :hide_goal_hit_message, :default => false
  flags :has_seen_tutorial, :default => false
  
  flags :notify_email_friend_requests, :default => true
  flags :notify_email_messages, :default => false
  flags :notify_email_challenges, :default => true
  flags :notify_email_events, :default => true

  flags :allow_daily_emails_monday, :default => false
  flags :allow_daily_emails_all_week, :default => true

  flags :stay_logged_in, :default => true
  flags :hide_kpw_stats, :default => false

  attr_privacy_no_path_to_user

  acts_as_notifier
  
  Role = {
    :user                       => "User",
    :location_coordinator       => "Location Coordinator",
    :regional_coordinator       => "Regional Coordinator",
    :coordinator                => "Coordinator",
    :reseller                   => "Reseller",
    :poster                     => "Poster",
    :master                     => "Master",
  }
  
  # pulling in friendships..
  
  has_many :friendships, :foreign_key => "friender_id", :dependent => :destroy
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => :friendee_id, :dependent => :destroy if HesFriendships.create_inverse_friendships

  has_many :email_reminders_sent, :order => "created_at DESC"
  has_many :email_reminders, :class_name => "EmailReminder", :through => :email_reminders_sent, :order => "email_reminders_sent.created_at DESC"
  
  after_create :associate_requested_friendships if HesFriendships.allows_unregistered_friends
  after_commit :welcome_email, :on => :create

  after_update :check_if_email_has_changed_and_associate_requested_friendships if HesFriendships.allows_unregistered_friends
  after_create :auto_accept_friendships if HesFriendships.auto_accept_friendships

  def friends
    @friends = self.class.where(:id => self.friendships.where(:status => Friendship::STATUS[:accepted]).collect(&:friendee_id))
  end

  # Requests a friendship from another user or email address
  #
  # @param [User, String] user_or_email of user if exists, otherwise just use email address
  # @return [Friendship] instance of your friendship with other user, status will be 'requested'
  # @example
  #  @target_user.request_friend(another_user)
  #  @target_user.request_friend("developer@hesonline.com")
  # @todo Try to find user if string is passed in. Not sure if good idea because will have to know structure of database for this to work.
  def request_friend(user_or_email)
    unless user_or_email.is_a?(String)
      friendships.create(:friendee => user_or_email, :status => Friendship::STATUS[:requested])
    else
      friendships.create(:friend_email => user_or_email, :status => Friendship::STATUS[:requested])
    end
  end

  def welcome_email
    Resque.enqueue(WelcomeEmail, self.id)
  end

  def welcome_notification
    notify(self, "User Created", "Welcome to #{Constant::AppName}! You will receive important notifications here.", :from => self, :key => "user_#{id}")
  end

  # Checks for friendship requests before user was registered by email address.
  # If any are found, updates friendships tied to other user while creating one for this user
  #
  # @param [String] email address if want to check for email not associated with user
  # @note Called in after_create by default
  def associate_requested_friendships(email = nil)
    Friendship.all(:conditions => ["(`#{Friendship.table_name}`.`friend_email` = :email) AND `#{Friendship.table_name}`.`status` = '#{Friendship::STATUS[:requested]}'", {:email => email || self.email}]).each do |f|
      friendships.create(:friendee => f.friender, :status => Friendship::STATUS[:pending])
      f.update_attributes(:friendee => self)
    end
  end

  # Checks to see if email address has changed after user is updated.
  # Calls check_for_requested_friendships if email was updated.
  # @see #check_for_requested_friendships
  def check_if_email_has_changed_and_associate_requested_friendships
    if email_was != email
      associate_requested_friendships
    end
  end
  
  # end friendships pulled in

  can_comment

  can_post
  can_like
  can_share
  can_rate
  has_notifications

  # relationships
  has_one :profile

  has_one :demographic

  # attrs
  attr_protected :role, :auth_key
  
  attr_privacy :email, :profile, :public
  attr_privacy :location, :top_level_location_id, :any_user
  attr_privacy :username, :tiles, :flags, :role, :promotion_id, :kpwalk_user_id, :kpwalk_level, :kpwalk_total_minutes, :kpwalk_total_stars, :active_device, :altid, :last_accessed, :me


  attr_accessible :username, :tiles, :email, :username, :altid, :promotion_id, :password, :profile, :profile_attributes, :flags, :location_id, :top_level_location_id, :active_device, :last_accessed

  # validation
  validates_presence_of :email, :role, :promotion_id, :organization_id, :reseller_id, :password
  validates_uniqueness_of :email, :scope => :promotion_id
  validates_uniqueness_of :altid, :scope => :promotion_id, :case_sensitve => false

  

#  default_scope :include => :profile, :order => "profiles.last_name ASC"

  belongs_to :promotion
  belongs_to :location
  has_many :entries, :order => :recorded_on
  has_many :evaluations, :dependent => :destroy
  has_many :events

  has_many :long_term_goals, :order => "created_at DESC"
  has_many :personal_action_plans

  has_many :created_challenges, :foreign_key => 'created_by', :class_name => "Challenge"

  has_many :challenges_sent, :class_name => "ChallengeSent", :order => "created_at DESC"
  has_many :challenges_received, :class_name => "ChallengeReceived", :order => "completed_on DESC, created_at DESC"

  expired_challenge_statuses = [ChallengeReceived::STATUS[:accepted]]
  has_many :expired_challenges, :class_name => "ChallengeReceived", :conditions => proc { "expires_on < '#{Time.now.utc.to_s(:db)}' AND status = #{expired_challenge_statuses.join(",")}" }, :order => "created_at DESC"

  has_many :unexpired_challenges, :class_name => "ChallengeReceived", :conditions => proc { "expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}'" }, :order => "created_at DESC"

  active_challenge_statuses = [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending], ChallengeReceived::STATUS[:accepted]]
  has_many :active_challenges, :class_name => "ChallengeReceived", :conditions => proc { "status IN (#{active_challenge_statuses.join(",")}) AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')" }, :order => "created_at DESC"

  challenge_queue_statuses = [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending]]
  has_many :challenge_queue, :class_name => "ChallengeReceived", :conditions => proc { "status IN (#{challenge_queue_statuses.join(",")}) AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')" }, :order => "created_at DESC"

  accepted_challenge_statuses = [ChallengeReceived::STATUS[:accepted]]
  has_many :accepted_challenges, :class_name => "ChallengeReceived", :conditions => proc { "status IN (#{accepted_challenge_statuses.join(",")}) AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')" }, :order => "created_at DESC"
  
  has_many :accepted_and_completed_challenges, :class_name => "ChallengeReceived", :conditions => proc { "(status = #{ChallengeReceived::STATUS[:accepted]} AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')) OR status = #{ChallengeReceived::STATUS[:completed]}" }, :order => "completed_on DESC, created_at DESC"

  has_many :suggested_challenges

  has_many :groups, :foreign_key => "owner_id"

  
  has_many :badges_earned, :class_name => "UserBadge", :include => :badge, :order => "badges.sequence ASC"
  has_many :badges, :through => :badges_earned

  # these two convoluted associations provide a means of getting the user's latest milestone badge earned
  has_one :current_milestone_earned, :class_name => "UserBadge", :include => :badge, :order => "earned_date DESC, badges.sequence DESC", :conditions => proc { "badges.badge_type = '#{Badge::TYPE[:milestones]}' AND YEAR(earned_date) = #{self.promotion.current_date.year}" }
  has_one :current_milestone, :class_name => "Badge", :through => :current_milestone_earned, :source => :badge, :foreign_key => "badge_id", :order => "earned_date DESC, badges.sequence DESC"
  
  accepts_nested_attributes_for :profile, :evaluations, :created_challenges, :challenges_received, :challenges_sent, :events, :badges_earned
  attr_accessor :include_evaluation_definitions
  
  # hooks
  after_initialize :set_default_values, :if => 'new_record?'
  before_validation :set_parents, :on => :create
  before_save :set_top_level_location



  # includes
  include HESUserMixins
  include BCrypt

  # methods
  def set_default_values
    self.role ||= Role[:user]
    self.auth_key ||= SecureRandom.hex(40)
  end

  def set_parents
    if self.promotion && self.promotion.organization
      self.organization_id = self.promotion.organization_id
      self.reseller_id = self.promotion.organization.reseller_id
    end
  end

  def set_top_level_location
    unless !self.location_id
      self.top_level_location_id = Location.find(self.location_id).top_location.id
    end
  end
  
  def serializable_hash(options={})
    hash = super(options)
    # TODO: this is gonna slow things down, need a much faster means of getting milestone for each user...
    ms = self.current_milestone
    hash["milestone_id"] = ms ? ms.id : nil
    return hash
  end

  def as_json(options={})
    user_json = super(options.merge(:include=>:profile))

    if self.include_evaluation_definitions || options[:include_evaluation_definitions]
      _evaluations_definitions = self.evaluations.collect{|x| x.definition.id}
      user_json["evaluation_definitions"] = _evaluations_definitions
    end
    user_json['stats'] = @stats if @stats
    user_json['recent_activities'] = @recent_activities if @recent_activities
    user_json['completed_evaluation_definition_ids'] = @completed_evaluation_definition_ids if @completed_evaluation_definition_ids
    user_json
  end

  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end

  def messages
    ChatMessage.by_userid(self.id)
  end

  def password
    return nil if !self.password_hash
    @password ||= Password.new(self.password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  # Gets the next evaluation definition for a user
  # @return [EvaluationDefinition] evaluation definition that hasn't been completed
  def get_next_evaluation_definition
    return @next_eval_definition if @next_eval_definition

    eval_definations = self.evaluations.collect{|x| x.definition}
    @next_eval_definition = (promotion.evaluation_definitions - eval_definations).first

    @next_eval_definition
  end

  def groups_with_user(user_id)
    sql = "
SELECT
groups.*
FROM groups
JOIN group_users ON groups.id = group_users.group_id
WHERE
groups.owner_id = #{self.id}
AND
group_users.user_id = #{user_id}
    "
    @result = Group.find_by_sql(sql)
    return @result
  end

  has_many :invites, :foreign_key => "invited_user_id"  

  # events associations that are too complex for Rails..
  has_many :events

  def subscribed_events(options = {})
    return self.events_query(options.merge({:type=>'subscribed'}))
  end
  
  def unresponded_events(options = {})
    return self.events_query(options.merge({:type=>'unresponded'}))
  end

  def maybe_events(options = {})
    return self.events_query(options.merge({:type=>'maybe'}))
  end

  def attending_events(options = {})
    return self.events_query(options.merge({:type=>'attending'}))
  end

  def declined_events(options = {})
    return self.events_query(options.merge({:type=>'declined'}))
  end

  def events_query(options = {})
    options = {
      :type             => options[:type] ||= 'subscribed',
      :start            => !options[:start].nil? ? options[:start].is_a?(String) ? options[:start] : options[:start].utc.to_s(:db) : nil,
      :end              => !options[:end].nil? ? options[:end].is_a?(String) ? options[:end] : options[:end].utc.to_s(:db) : nil,
      :id               => options[:id] ||= nil,
      :return           => options[:return] ||= 'array',
      :include_canceled => options[:include_canceled] ||= false
    }
    # select statement is at the end of this function..
    sql = "
FROM events
LEFT JOIN invites my_invite ON my_invite.event_id = events.id AND (my_invite.invited_user_id = #{self.id})
LEFT JOIN invites all_invites ON all_invites.event_id = events.id
JOIN users on events.user_id = users.id
JOIN profiles on profiles.user_id = users.id
WHERE
(
    "
    case options[:type]
      when 'unresponded'
        sql += "
  # UNRESPONDED
  # my friends events with privacy = all_friends
  (
    (
      events.user_id in (select friendee_id from friendships where (friender_id = #{self.id}) AND friendships.status = 'A')
    )
    AND events.user_id <> #{self.id}
    AND events.privacy = 'F'
    # invite doesn't exist or is unresponded
    AND (
      my_invite.status IS NULL
      OR
      my_invite.status = #{Invite::STATUS[:unresponded]}
    )
  )
  OR
  # events i'm invited to
  (
    my_invite.invited_user_id = #{self.id}
    AND my_invite.status = #{Invite::STATUS[:unresponded]}
  )
  OR
  # coordinator events in my area
  (
    events.event_type = 'C'
    AND events.privacy = 'L'
    AND (events.location_id IS NULL #{"OR events.location_id IN (" + [self.location_id, self.top_level_location_id].join(',') + ")" if self.location_id})
    # invite doesn't exist or is unresponded
    AND (
      my_invite.status IS NULL
      OR
      my_invite.status = #{Invite::STATUS[:unresponded]}
    )
  )
        "
      when 'maybe'
        sql += "
  # MAYBE
  # events i'm invited to
  (
    my_invite.invited_user_id = #{self.id}
    AND my_invite.status = #{Invite::STATUS[:maybe]}
  )
        "
      when 'attending'
        sql += "
  # ATTENDING
  # my events
  (
    events.user_id = #{self.id}
  )
  OR
  # my invites
  (
    my_invite.status = #{Invite::STATUS[:attending]}
  )
        "
      when 'declined'
        sql += "
  # DECLINED
  # events i'm invited to
  (
    my_invite.invited_user_id = #{self.id}
    AND my_invite.status = #{Invite::STATUS[:declined]}
  )
        "
    when "subscribed"
      sql += "
  # SUBSCRIBED
  # my events
  (
    events.user_id = #{self.id}
  )
  OR
  # my friends events with privacy = all_friends
  (
    (
      events.user_id in (select friendee_id from friendships where (friender_id = #{self.id}) AND friendships.status = 'A')
    )
    AND events.user_id <> #{self.id}
    AND events.privacy = 'F'
  )
  OR
  # events i'm invited to
  (
    my_invite.invited_user_id = #{self.id}
  )
  OR
  # coordinator events in my area
  (
    events.event_type = 'C'
    AND events.privacy = 'L'
    AND (events.location_id IS NULL #{"OR events.location_id IN (" + [self.location_id, self.top_level_location_id].join(',') + ")" if self.location_id})
  )
      "
    else
      # default events
      return Event.find_by_sql("SELECT * FROM events WHERE events.user_id = #{self.id}")
    end
    sql += "
)
#{"AND events.start >= '" + options[:start] + "'" if !options[:start].nil?}
#{"AND events.end <= '" + options[:end] + "'" if !options[:end].nil?}
#{"AND events.id = " + options[:id].to_s if !options[:id].nil?}
#{"AND events.is_canceled = 0" unless options[:include_canceled]}
GROUP BY events.id
ORDER BY events.start ASC
    "
    case options[:return]
      when 'count'
      sql = "
SELECT
COUNT(DISTINCT(events.id)) AS total_events
" + sql
        @result = Event.count_by_sql(sql)
    else
      # default/"array"
      sql = "
SELECT
events.*
" + sql
      @result = Event.find_by_sql(sql)
    end
    return @result
  end

  def unassociated_search(search, limit = 0)
    sql = "
SELECT users.*
FROM users
JOIN profiles ON profiles.user_id = users.id
LEFT JOIN friendships ON (((friendships.friendee_id = users.id AND friendships.friender_id = #{self.id}) OR (friendships.friendee_id = #{self.id} AND friendships.friender_id = users.id)))
WHERE
(
  users.email LIKE '%#{search}%'
  OR profiles.first_name like '#{search}%'
  OR profiles.last_name like '%#{search}%'
  OR CONCAT(profiles.first_name, ' ', profiles.last_name) LIKE '#{search}%'
)
AND
(
  users.id <> #{self.id}
  AND (
    friendships.status IS NULL
    OR friendships.status = 'D'
  )
  AND users.promotion_id = #{self.promotion_id}
)
GROUP BY users.id
ORDER BY profiles.last_name
#{'LIMIT ' + limit.to_s if limit > 0}
    "
    users = User.find_by_sql(sql)
    ActiveRecord::Associations::Preloader.new(users, :profile).run
    return users
  end

  def posters(options = {})
    user = self
    options[:unlocked_only] ||= false
    options[:start] ||= user.promotion.current_date.beginning_of_week
    options[:end] ||= user.promotion.current_date.end_of_week
    sql = "
SELECT
IF(
  IF(entries.exercise_minutes > 0, 1, 0)
  OR
  IF(entries.exercise_steps > 0, 1, 0)
  , 1, 0) AS unlocked,
posters.id, posters.visible_date, posters.summary, posters.content, posters.success_story_id, posters.title
FROM posters
LEFT JOIN entries ON entries.user_id = #{user.id}
  AND (
    entries.recorded_on = posters.visible_date
    OR (
      -- saturday's entry lines up with friday
      WEEKDAY(entries.recorded_on) = 5 AND DATE_SUB(entries.recorded_on, INTERVAL 1 DAY) = posters.visible_date
      OR
      -- sunday's entry lines up with friday
      WEEKDAY(entries.recorded_on) = 6 AND DATE_SUB(entries.recorded_on, INTERVAL 2 DAY) = posters.visible_date
    )
  )
WHERE
posters.visible_date BETWEEN '#{options[:start]}' AND '#{options[:end]}'
AND posters.active = 1
AND posters.visible_date <= '#{user.promotion.current_date}'
GROUP BY posters.visible_date, entries.recorded_on
ORDER BY posters.visible_date DESC, entries.recorded_on DESC
    "
    posters_array = []
    last = nil
    Poster.connection.select_all(sql).each do |row|
      if last && last['visible_date'] == row['visible_date']
        if row['unlocked'] === 1
          posters_array.pop
          posters_array.push(row)
        end
      else
        posters_array.push(row)
      end
      last = row
    end

    # remove posters if they cannot possibly unlock them (poster visible date is earlier than backlog date)
    posters_array.each_with_index{|poster,index|
      if poster['visible_date'].to_date < self.profile.backlog_date && poster['unlocked'] < 1
        posters_array.delete_at(index)
      end
    }

    loaded_posters = Poster.where(:id => posters_array.collect{|p|p['id']}).order("posters.visible_date DESC")

    posters_array.each_with_index{|poster,index|
      posters_array[index]['image1'] = loaded_posters[index].image1.serializable_hash
      posters_array[index]['image2'] = loaded_posters[index].image2.serializable_hash
    }

    return posters_array
  end

  def self.stats(user_ids,year)
    user_ids = [user_ids] unless user_ids.is_a?(Array)
    user = self
    sql = "
      SELECT
      entries.user_id AS user_id,
      SUM(exercise_points) AS total_exercise_points,
      SUM(challenge_points) AS total_challenge_points,
      SUM(timed_behavior_points) AS total_timed_behavior_points,
      SUM(exercise_steps) AS total_exercise_steps,
      SUM(exercise_minutes) AS total_exercise_minutes,
      SUM(exercise_points) + SUM(challenge_points) + SUM(timed_behavior_points) AS total_points,
      AVG(exercise_minutes) AS average_exercise_minutes,
      AVG(exercise_steps) AS average_exercise_steps
      FROM
      entries
      WHERE
      user_id in (#{user_ids.join(',')})
      AND YEAR(recorded_on) = #{year}
      GROUP BY user_id
    "
    # turns [1,2,3] into {1=>{},2=>{},3=>{}} where each sub-hash is missing data (to be replaced by query)
    keys = ['total_exercise_points','total_challenge_points','total_timed_behavior_points','total_exercise_steps','total_exercise_minutes','total_points','average_exercise_minutes','average_exercise_steps']
    zeroes = Hash[*keys.collect{|k|[k,0]}.flatten]
    user_stats = Hash[*user_ids.collect{|id|[id,zeroes]}.flatten]
    self.connection.select_all(sql).each do |row|
      user_stats[row['user_id'].to_i] = row
    end
    return user_stats
  end

  def stats(year = self.promotion.current_date.year)
    unless @stats
      arr =  self.class.stats([self.id],year)
      @stats = arr[self.id]
    end
    @stats
  end

  def stats=(hash)
    @stats=hash
  end

  # KEEP ME
  # this was the original way of determining which posters a user has unlocked
  # leaving it here for now, cuz they'll probably change their minds and this was a nice quick implementation
  # that took some thought and time
  def posters_original(options = {})
    user = self
    options[:unlocked_only] ||= false
    options[:start] ||= user.promotion.current_date.beginning_of_week
    options[:end] ||= user.promotion.current_date.end_of_week
    sql = "
SELECT
IF(
  -- entry's minutes is greater than the goal minutes of the entry, fall back on profile
  IF(entries.exercise_minutes > COALESCE(entries.goal_minutes, profiles.goal_minutes, 0), 1, 0)
  OR
  -- entry's steps is greater than the goal steps of the entry, fall back on profile
  IF(entries.exercise_steps > COALESCE(entries.goal_steps, profiles.goal_steps, 0), 1, 0)
  , 1, 0) AS unlocked,
posters.id, posters.visible_date, posters.summary, posters.content, posters.success_story_id, posters.title
FROM posters
LEFT JOIN entries ON entries.user_id = #{user.id}
  AND (
    entries.recorded_on = posters.visible_date
    OR (
      -- saturday's entry lines up with friday
      WEEKDAY(entries.recorded_on) = 5 AND DATE_SUB(entries.recorded_on, INTERVAL 1 DAY) = posters.visible_date
      OR
      -- sunday's entry lines up with friday
      WEEKDAY(entries.recorded_on) = 6 AND DATE_SUB(entries.recorded_on, INTERVAL 2 DAY) = posters.visible_date
    )
  )
LEFT JOIN profiles ON profiles.user_id = entries.user_id
WHERE
posters.visible_date BETWEEN '#{options[:start]}' AND '#{options[:end]}'
AND posters.active = 1
AND posters.visible_date <= '#{user.promotion.current_date}'
GROUP BY posters.visible_date, entries.recorded_on
ORDER BY posters.visible_date DESC, entries.recorded_on DESC
    "
    posters_array = []
    last = nil
    Poster.connection.select_all(sql).each do |row|
      if last && last['visible_date'] == row['visible_date']
        if row['unlocked'] === 1
          posters_array.pop
          posters_array.push(row)
        end
      else
        posters_array.push(row)
      end
      last = row
    end

    loaded_posters = Poster.where(:id => posters_array.collect{|p|p['id']}).order("posters.visible_date DESC")

    posters_array.each_with_index{|poster,index|
      posters_array[index]['image1'] = loaded_posters[index].image1.serializable_hash
      posters_array[index]['image2'] = loaded_posters[index].image2.serializable_hash
    }

    return posters_array
  end

  def location_ids
    # a helper method to return all location ids of a user..
    # right now it's just 2, but in theory it could be more
    # so this can return a flattened array of all ids
    return [self.location_id,self.top_level_location_id]
  end

  def email_with_name
    return "#{self.profile.full_name} <#{self.email}>"
  end

  def completed_evaluation_definition_ids
    unless @completed_evaluation_definition_ids
      @completed_evaluation_definition_ids = self.evaluations.collect{|e|e.evaluation_definition_id}
    end
    return @completed_evaluation_definition_ids
  end

  def completed_evaluation_definition_ids=(array)
    @completed_evaluation_definition_ids = array
  end

  def process_last_accessed
    self.update_attributes(:last_accessed => self.promotion.current_time) if !self.last_accessed || self.last_accessed.to_date < self.promotion.current_date
    days_since_last_accessed = self.promotion.current_date - self.last_accessed.to_date
    reminder = self.promotion.email_reminders.asc.where("days <= #{days_since_last_accessed}").first
    if reminder && !reminder.welcome_back_notification.nil? && !reminder.welcome_back_message.nil?
      notify(self, "Welcome Back", reminder.welcome_back_notification, :from => self, :key => "user_#{id}")
      $redis.publish('welcomeBackMessage', {:message => reminder.welcome_back_message, :user_id => self.id}.to_json)
    end
  end

  def recent_activities(id_only = false, limit = 5)
    sql = "
      SELECT
        DISTINCT(exercise_activities.id) AS id
      FROM entries
      JOIN rel_entries_exercises_activities ON rel_entries_exercises_activities.entry_id = entries.id
      JOIN exercise_activities ON exercise_activities.id = rel_entries_exercises_activities.exercise_activity_id
      WHERE
        entries.user_id = #{self.id}
        AND entries.recorded_on <= '#{self.promotion.current_date}'
      GROUP BY exercise_activities.id
      ORDER BY MAX(rel_entries_exercises_activities.updated_at) DESC
      LIMIT #{limit}
    "
    result = self.connection.exec_query(sql)
    ids = []
    result.each{ |row|
      ids << row['id']
    }
    if id_only  
      return ids
    end
    return ExerciseActivity.find(ids)
  end

  def recent_activities=(hash)
    @recent_activities = hash
  end

end
