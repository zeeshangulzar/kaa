class Promotion < ApplicationModel

  attr_accessible :flags, *column_names
  
  attr_privacy_no_path_to_user
  
  attr_privacy :subdomain, :customized_files, :theme, :launch_on, :ends_on, :organization, :registration_starts_on, :registration_ends_on, :late_registration_ends_on, :logo, :is_active, :flags, :current_date, :max_participants, :logging_ends_on, :disabled_on, :location_labels, :organization, :public
  attr_privacy :starts_on, :ends_on, :steps_point_thresholds, :minutes_point_thresholds, :gifts_point_thresholds, :behaviors_point_thresholds, :program_length, :behaviors, :backlog_days, :resources_title, :name, :status, :version, :program_name, :gifts, :current_competition, :weekly_goal, :any_user
  attr_privacy :pilot_password, :master

  belongs_to :organization

  has_many :eligibilities
  has_many :custom_eligibility_fields, :order => "sequence ASC"
  has_many :eligibility_files

  has_many :custom_content
  # override this for default promotion..
  def custom_content
    if self.is_default?
      return CustomContent.where(:promotion_id => nil)
    end
    super
  end

  has_many :users
  has_many :behaviors, :order => "sequence ASC"
  has_many :gifts
  has_many :exercise_activities, :order => "name ASC"
  has_many :point_thresholds, :as => :pointable, :order => 'min DESC'
  has_many :email_reminders
  has_many :unsubscribe_list
  has_many :resources
  has_many :competitions
  has_many :notifications, :as => :notificationable, :order => 'created_at DESC'
  has_many :teams

  DEFAULT_SUBDOMAIN = 'www'
  DASHBOARD_SUBDOMAIN = 'dashboard'

  has_custom_prompts :with => :evaluations

  has_many :locations, :order => "parent_location_id, sequence, name", :dependent => :destroy

  has_wall
  has_evaluations
  has_reports

  mount_uploader :logo, PromotionLogoUploader

  after_create :copy_defaults

  after_update :update_evaluations, :if => lambda { self.program_length != self.program_length_was }

  flags :is_fitbit_enabled, :default => false
  flags :is_jawbone_enabled, :default => false
  flags :is_manual_override_enabled, :default => false
  flags :is_teams_enabled, :default => false
  flags :is_gender_displayed, :default => false
  flags :is_show_individual_leaderboard, :default => false
  flags :is_location_displayed, :default => false
  flags :is_social_media_displayed, :default => false
  flags :is_wall_enabled, :default => false
  flags :is_mapwalk_enabled, :default => false
  flags :is_resources_enabled, :default => false
  flags :is_address_enabled, :default => false
  flags :is_feedback_enabled, :default => false
  flags :is_video_enabled, :default => false
  flags :fulfillment_monday, :fulfillment_tuesday, :fulfillment_wednesday, :fulfillment_thursday, :fulfillment_friday, :fulfillment_saturday, :fulfillment_sunday, :default => false
  flags :is_eligibility_displayed, :default => false

  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :subdomain, :launch_on, :starts_on, :registration_starts_on
  validates_uniqueness_of :subdomain

  def self.active_scope_sql
    return "is_active = 1 AND launch_on <= '#{Date.today.to_s(:db)}' AND (ends_on IS NULL OR ends_on >= '#{Date.today.to_s(:db)}') AND (disabled_on IS NULL OR disabled_on >= '#{Date.today.to_s(:db)}') AND subdomain NOT IN ('#{Promotion::DEFAULT_SUBDOMAIN}', '#{Promotion::DASHBOARD_SUBDOMAIN}')"
  end

  # apparently it's important that this scope be defined after everything it depends on..
  scope :active, where(self.active_scope_sql)

  def as_json(options={})
    options[:meta] ||= false
    promotion_obj = super(options)
    return promotion_obj
  end

  def current_date
    ActiveSupport::TimeZone[time_zone].today()
  end

  def current_time
    ActiveSupport::TimeZone[time_zone].now()
  end

  def current_day
    return Promotion::get_day_from_date(self, self.current_date)
  end

  def self.get_day_from_date(promotion, date = nil)
    weekdays = 0
    if date.nil?
      date = promotion.current_date
    end
    while date >= promotion.starts_on
      weekdays += 1 unless [0,6].include?(date.wday)
      date = date - 1.day
    end
    return weekdays
  end

  def steps_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "STEPS"}, :order => 'min DESC')
  end

  def minutes_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "MINUTES"}, :order => 'min DESC')
  end

  def gifts_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "GIFTS"}, :order => 'min DESC')
  end

  def behaviors_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "BEHAVIORS"}, :order => 'min DESC')
  end

  def copy_defaults
    default = Promotion::get_default
    if default
      self.copy_point_thresholds
      self.copy_behaviors
      self.copy_gifts
      self.copy_custom_prompts
    end
    self.create_evaluations
  end

  def copy_point_thresholds
    default = Promotion::get_default
    default.point_thresholds.each{|pt|
      copied_pt = pt.dup
      copied_pt.id = nil
      copied_pt.pointable_id = self.id
      copied_pt.save!
    }
  end

  # TODO: test copying of images
  def copy_behaviors
    default = Promotion::get_default
    default.behaviors.each{|b|
      copied_b = b.dup
      copied_b.id = nil
      copied_b.promotion_id = self.id
      copied_b.save!
    }
  end

  # TODO: test copying of images
  def copy_gifts
    default = Promotion::get_default
    default.gifts.each{|g|
      copied_g = g.dup
      copied_g.id = nil
      copied_g.promotion_id = self.id
      copied_g.save!
    }
  end

  # copy default promo custom prompts for evals, etc.
  def copy_custom_prompts
    default = Promotion::get_default
    if default
      default.custom_prompts.each{|cp|
        copied_cp = cp.dup
        copied_cp.id = nil
        copied_cp.custom_promptable_id = self.id
        copied_cp.save!
      }
    end
  end

  # Creates the initial assesement used at registration and the final assessment used at the program end
  def create_evaluations
    Promotion.transaction do
      default = Promotion::get_default
      if default
        # copy default promo evaluations
        default.evaluation_definitions.each{|ed|
          copied_ed = ed.dup
          copied_ed.id = nil
          copied_ed.eval_definitionable_id = self.id
          copied_ed.save!
        }
      else
        initial_evaluation = self.evaluation_definitions.create!(:name => "Initial Assessment", :days_from_start => 0)
        program_end_evaluation = self.evaluation_definitions.create!(:name => "Program End Evaluation", :days_from_start => self.program_length - 1)
      end
    end
  end

  # Updates the last evaluation that is tied to the ends_on date
  def update_evaluations
    end_evaluation = self.evaluation_definitions.where(:days_from_start => self.program_length_was).first
    end_evaluation.update_attributes(:days_from_start => self.program_length) unless end_evaluation.nil?

    true
  end

  def customized_files(custom_name=self.subdomain,dir='public',refresh=false)
    paths = {}
    if !$custom_partials_cache || refresh
      $custom_partials_cache = Dir.glob(File.join(dir,'/**/*'))
    end
    $custom_partials_cache.each do |item|
      # only look at files, not dirs
      if File.file?(item)
        # chop off the path and extension, and examine the file name  (e.g. turn bla/bla/bla/something_abc.text.html into something_abc)
        dir_name = File.dirname(item)
        file_name = File.basename(item)
        without_extension = file_name.split('.').first
        underscored_custom_name = "_#{custom_name}" 
        if without_extension =~ /#{underscored_custom_name}$/
          # at this point, we seem to have found a file named something_abc... let's see if there's a file named something without _abc at the end
          # if we find something and something_abc, then we can assume something_abc is a customized version of something
          non_customized_file_name = File.join(dir_name,file_name.gsub(underscored_custom_name,''))
          if File.exists?(non_customized_file_name)
            # we have a match.  something_abc is a customized version of something
            paths[non_customized_file_name] = item
          end
        end
      end
    end
    paths
  end

  def nested_locations?
    location_labels_as_array.size>1
  end

  def location_labels
    self.read_attribute(:location_labels).to_s.empty? ? ['Location'] : self.read_attribute(:location_labels).split("|").map(&:strip)
  end

  # def location_labels_as_array
  #   location_labels.to_s.empty? ? [self.location_labels||'Location'] : location_labels.split("\n").collect{|x|x.split("|").first}
  # end

  def nested_locations(reload=false)
    cache_key = "promotion_#{self.id}_nested_locations"
    Rails.cache.delete(cache_key) if reload
    @nested_locations = Rails.cache.fetch(cache_key) {
      nested = []
      self.locations.each do |location|
        if location.top?
          location = self.get_kids(location)
          nested.push(location)
        end
      end
      Rails.logger.warn("building nested locations cache for promotion: #{self.id}")
      nested_locations = nested.as_json(:include => :locations)
      nested_locations
    }
    return @nested_locations
  end

  def get_kids(location, parents = [])
    location[:parents] = parents.dup
    parents.push(location.id)
    location.children.each do |child|
      location[:locations] = [] if location[:locations].nil?
      child = self.get_kids(child, parents.dup)
      location['locations'].push(child)
    end
    return location
  end

  def logo_for_user(user=nil)
    if user && user.location && user.location.parent_location && !user.location.parent_location.logo.nil?
      return user.location.parent_location.logo.as_json[:logo]
    end
    return self.logo
  end

  def resources_title_for_user(user=nil)
    if user && user.location && user.location.parent_location && !user.location.parent_location.resources_title.nil?
      return user.location.parent_location.resources_title
    end
    return self.resources_title
  end

  def custom_content_path
    "#{Rails.root}/content/#{subdomain}#{id}"
  end

  def current_competition(today = self.current_date)
    if today != current_date
      #if you pass in some other date, i don't want it to affect the class variable
      #(i.e. i don't want to cache "some other" competition and call it current)
      comp = competitions.find(:first,:conditions=>["enrollment_starts_on <= :today and :today <= enrollment_ends_on", {:today=>today}])
    else
      # this is stuffed into a class variable because this could get called multiple times in a request, resulting in redundant queries
      if @current_competition.nil?
        # any idea how to make :conditions not be glued to MySQL?  do we care?  should we care?  could we care if we were capable of caring?
        comp = @current_competition = competitions.find(:first,:conditions=>["enrollment_starts_on <= :today and :today <= competition_ends_on", {:today=>today}])
      else
        comp = @current_competition
      end
    end
    comp || competitions.find( :last, :conditions => [ "enrollment_starts_on <= :today", { :today => today } ] )
  end

  def is_default?
    return self.subdomain == Promotion::DEFAULT_SUBDOMAIN
  end

  def is_dashboard?
    return self.subdomain == Promotion::DASHBOARD_SUBDOMAIN
  end

  def self.get_default
    return Promotion.where(:subdomain => Promotion::DEFAULT_SUBDOMAIN).first rescue nil
  end

  def keywords
    return {
      'APP_NAME'        => Constant::AppName,
      'NAME'            => self.name,
      'COMP_REG_STARTS' => self.current_competition.nil? ? Date.today : self.current_competition.enrollment_starts_on.strftime("%A, %B #{self.current_competition.enrollment_starts_on.day}, %Y"),
      'COMP_REG_ENDS'   => self.current_competition.nil? ? Date.today : self.current_competition.enrollment_ends_on.strftime("%A, %B #{self.current_competition.enrollment_ends_on.day}, %Y"),
      'COMP_STARTS'     => self.current_competition.nil? ? Date.today : self.current_competition.competition_starts_on.strftime("%A, %B #{self.current_competition.competition_starts_on.day}, %Y"),
      'COMP_END'        => self.current_competition.nil? ? Date.today : self.current_competition.competition_ends_on.strftime("%A, %B #{self.current_competition.competition_ends_on.day}, %Y"),
      'LAUNCHES_ON'     => self.launch_on.nil? ? Date.today : self.launch_on.strftime("%A, %B #{self.launch_on.day}, %Y"),
      'STARTS_ON'       => self.starts_on.nil? ? Date.today : self.starts_on.strftime("%A, %B #{self.starts_on.day}, %Y"),
      'ENDS_ON'         => self.ends_on.nil? ? Date.today : self.ends_on.strftime("%A, %B #{self.ends_on.day}, %Y"),
      'REG_STARTS'      => self.registration_starts_on.nil? ? Date.today : self.registration_starts_on.strftime("%A, %B #{self.registration_starts_on.day}, %Y"),
      'REG_ENDS'        => self.registration_ends_on.nil? ? Date.today : self.registration_ends_on.strftime("%A, %B #{self.registration_ends_on.day}, %Y"),
      'LENGTH_IN_DAYS'  => self.program_length,
      'LENGTH_IN_WEEKS' => (self.program_length/7.0).ceil,
      'BASE_URL'        => "https://#{self.subdomain}.#{DomainConfig::DomainNames.first}"
    }
  end

  def individual_leaderboard(conditions = {}, count = false)

    # filter junk out...
    sort_columns = ['name', 'total_points']
    conditions.delete(:sort) if !conditions[:sort].nil? && !sort_columns.include?(conditions[:sort])
    conditions.delete(:sort_dor) if !conditions[:sort_dir].nil? && !['ASC', 'DESC'].include?(conditions[:sort_dir].upcase)
    conditions.delete(:offset) if !ApplicationHelper::is_i?(conditions[:offset])
    conditions.delete(:limit) if !ApplicationHelper::is_i?(conditions[:limit])

    conditions = {
      :offset       => nil,
      :limit        => 99999999999, # if we have more users than this, we've got bigger problems to worry about
      :location_ids => [],
      :sort         => "total_points",
      :sort_dir     => "DESC"
    }.nil_merge!(conditions)

    users_sql = "
      SELECT
    "
    if count
      users_sql = users_sql + " COUNT(DISTINCT(users.id)) AS user_count"
    else
      users_sql = users_sql + "
        users.id, profiles.first_name, profiles.last_name, profiles.image, users.location_id, users.top_level_location_id, users.total_points,
        locations.id AS location_id, locations.name AS location_name
      "
    end
    users_sql = users_sql + "
      FROM users
        JOIN profiles ON profiles.user_id = users.id
        LEFT JOIN locations ON locations.id = users.location_id
      WHERE
        users.promotion_id = #{self.id}
        AND users.opted_in_individual_leaderboard = 1
        #{"AND (users.location_id IN (#{conditions[:location_ids].join(',')}) OR users.top_level_location_id IN (#{conditions[:location_ids].join(',')}))" if !conditions[:location_ids].empty?}
    "
    if !count
      users_sql = users_sql + "
        GROUP BY users.id
        ORDER BY #{conditions[:sort]} #{conditions[:sort_dir]}
        #{"LIMIT " + conditions[:offset].to_s + ", " + conditions[:limit].to_s if !conditions[:offset].nil? && !conditions[:limit].nil?}
        #{"LIMIT " + conditions[:limit].to_s if conditions[:offset].nil? && !conditions[:limit].nil?}
      "
    end
    result = self.connection.exec_query(users_sql)
    if count
      return result.first['user_count']
    end
    users = []
    rank = 0
    user_count = 0
    previous_user = nil
    result.each{|row|
      user_count += 1
      user = {}
      user['profile']                 = {}
      user['profile']['image']        = {}
      user['location']                = {}
      user['id']                      = row['id']
      user['profile']['image']['url'] = row['image'].nil? ? ProfilePhotoUploader::default_url : ProfilePhotoUploader::asset_host_url + row['image'].to_s
      user['profile']['first_name']   = row['first_name']
      user['profile']['last_name']    = row['last_name']
      user['location']['id']          = row['location_id']
      user['location']['name']        = row['location_name']
      user['total_points']            = row['total_points']
      rank = user_count if (!previous_user || previous_user['total_points'] > user['total_points'])
      user['rank']                    = rank
      users << user
      previous_user = user
    }

    return users
  end

  def total_participants
    return self.users.where("users.email NOT LIKE '%hesapps%' AND users.email NOT LIKE '%hesonline%'").count
  end

  def eligibility_fields
    unless @eligibility_fields
      fields = Eligibility::DEFAULT_FIELDS
      if self.custom_eligibility_fields
        custom_fields = self.custom_eligibility_fields.collect{ |cef| cef.name }
        fields = fields + custom_fields
      end
      @eligibility_fields = fields
    end
    return @eligibility_fields
  end

end
