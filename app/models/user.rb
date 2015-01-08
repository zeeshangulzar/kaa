require 'bcrypt'

class User < ApplicationModel

  has_friendships

  # attrs
  attr_protected :role, :auth_key
  attr_privacy_no_path_to_user
  attr_privacy :email, :public
  attr_privacy :location, :any_user
  attr_privacy :username, :tiles, :me
  attr_accessible :username, :tiles, :email, :username, :altid

  # validation
  validates_presence_of :email, :role, :promotion_id, :organization_id, :reseller_id, :username, :password
  validates_uniqueness_of :email, :scope => :promotion_id

  # relationships
  has_one :profile, :in_json => true
  belongs_to :promotion
  belongs_to :location
  has_many :entries, :order => :recorded_on
  has_many :evaluations, :dependent => :destroy
  has_many :events

  has_notifications

  can_post
  can_like

  has_many :messages, :class_name => "ChatMessage", :conditions => proc { "(user_id = #{self.id} OR friend_id = #{self.id})" }

  has_many :created_challenges, :foreign_key => 'created_by', :class_name => "Challenge"

  has_many :challenges_sent, :class_name => "ChallengeSent", :order => "created_at DESC"
  has_many :challenges_received, :class_name => "ChallengeReceived"

  expired_challenge_statuses = [ChallengeReceived::STATUS[:accepted]]
  has_many :expired_challenges, :class_name => "ChallengeReceived", :conditions => proc { "expires_on < '#{Time.now.utc.to_s(:db)}' AND status = #{expired_challenge_statuses.join(",")}" }

  has_many :unexpired_challenges, :class_name => "ChallengeReceived", :conditions => proc { "expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}'" }

  active_challenge_statuses = [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending], ChallengeReceived::STATUS[:accepted]]
  has_many :active_challenges, :class_name => "ChallengeReceived", :conditions => proc { "status IN (#{active_challenge_statuses.join(",")}) AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')" }

  challenge_queue_statuses = [ChallengeReceived::STATUS[:unseen], ChallengeReceived::STATUS[:pending]]
  has_many :challenge_queue, :class_name => "ChallengeReceived", :conditions => proc { "status IN (#{challenge_queue_statuses.join(",")}) AND (expires_on IS NULL OR expires_on >= '#{Time.now.utc.to_s(:db)}')" }

  has_many :suggested_challenges

  has_many :groups, :foreign_key => "owner_id"
  
  accepts_nested_attributes_for :profile, :evaluations, :created_challenges, :challenges_received, :challenges_sent, :events
  attr_accessor :include_evaluation_definitions
  
  # hooks
  after_initialize :set_default_values, :if => 'new_record?'
  before_validation :set_parents, :on => :create

  # constants
  Role = {
    :user                       => "User",
    :master                     => "Master",
    :reseller                   => "Reseller",
    :coordinator                => "Coordinator",
    :sub_promotion_coordinator  => "Sub Promotion Coordinator",
    :location_coordinator       => "Location Coordinator",
    :poster                     => "Poster"
  }

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

  def as_json(options={})
    user_json = super(options.merge(:include=>:profile))

    if self.include_evaluation_definitions || options[:include_evaluation_definitions]
      _evaluations_definitions = self.evaluations.collect{|x| x.definition.id}
      user_json["evaluation_definitions"] = _evaluations_definitions
    end

    user_json
  end

  def auth_basic_header
    b64 = Base64.encode64("#{self.id}:#{self.auth_key}").gsub("\n","")
    "Basic #{b64}"
  end

  def has_made_self_known_to_public?
    return true
  end

  def password
    @password ||= Password.new(password_hash)
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

  # TODO: not really using this but it may be nice to have sooo decide whether to keep..
  def groups_with_user(user_id)
    sql = "
SELECT
groups.*
FROM groups
JOIN group_users ON groups.id = group_users.group_id
WHERE
groups.owner_id = #{self.id}
AND
group_users.user_id = #{friend_id}
    "
    @result = Group.find_by_sql(sql)
    return @result
  end

  has_many :invites, :foreign_key => "invited_user_id"  

  # events associations that are too complex for Rails..
  # TODO: this is inefficient.. the sql is ok, but the Event.find_by_sql() and resulting ActiveRecord crap will likely be a huge performance hit down the road
  # need to figure out a way to populate/simulate ActiveRecord objects through this query, including the necessary associations and pagination (invites especially)

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
      :type   => options[:type] ||= 'subscribed',
      :start  => !options[:start].nil? ? options[:start].is_a?(String) ? options[:start] : options[:start].utc.to_s(:db) : nil,
      :end    => !options[:end].nil? ? options[:end].is_a?(String) ? options[:end] : options[:end].utc.to_s(:db) : nil,
      :id     => options[:id] ||= nil,
      :return => options[:return] ||= 'array'
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
      OR
      events.user_id in (select friender_id from friendships where (friendee_id = #{self.id}) AND friendships.status = 'A')
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
    AND (events.location_id IS NULL OR events.location_id = #{self.location_id})
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
  # my friends events with privacy = all_friends
  (
    (
      events.user_id in (select friendee_id from friendships where (friender_id = #{self.id}) AND friendships.status = 'A')
      OR
      events.user_id in (select friender_id from friendships where (friendee_id = #{self.id}) AND friendships.status = 'A')
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
    AND (events.location_id IS NULL OR events.location_id = #{self.location_id})
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
      OR
      events.user_id in (select friender_id from friendships where (friendee_id = #{self.id}) AND friendships.status = 'A')
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
    AND (events.location_id IS NULL OR events.location_id = #{self.location_id})
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
events.*, COUNT(DISTINCT all_invites.id) AS total_invites
" + sql
      @result = Event.find_by_sql(sql)
    end
    return @result
  end


end
