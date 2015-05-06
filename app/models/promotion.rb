class Promotion < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :subdomain, :customized_files, :theme, :launch_on, :ends_on, :public

  attr_privacy :starts_on, :ends_on, :steps_point_thresholds, :minutes_point_thresholds, :program_length, :behaviors, :exercise_activities, :challenges, :static_tiles, :dynamic_tiles, :backlog_days, :badges, :resources_title, :name, :any_user

  belongs_to :organization

  has_many :users
  has_many :behaviors
  has_many :exercise_activities, :order => "name ASC"
  has_many :point_thresholds, :as => :pointable, :order => 'min DESC'
  has_many :posters, :order => 'visible_date DESC'
  has_many :success_stories, :order => 'created_at DESC'
  has_many :email_reminders

  has_many :challenges
  has_many :suggested_challenges

  has_many :unsubscribe_list

  has_many :badges, :order => "sequence ASC"

  has_many :resources
  has_many :banners

  has_many :competitions

  has_custom_prompts :with => :evaluations

  has_many :locations, :order => "parent_location_id, name", :dependent => :destroy

  has_wall
  has_evaluations

  has_reports

  mount_uploader :logo, PromotionLogoUploader

  after_create :create_evaluations
  after_update :update_evaluations, :if => lambda { self.program_length != self.program_length_was }

  flags :is_fitbit_enabled, :default => false
  flags :is_jawbone_enabled, :default => false
  flags :is_manual_override_enabled, :default => false

  self.after_save :clear_hes_cache
  self.after_destroy :clear_hes_cache

  after_commit :clear_cache

  def current_date
    ActiveSupport::TimeZone[time_zone].today()
  end

  def current_time
    ActiveSupport::TimeZone[time_zone].now()
  end

  def steps_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "STEPS"}, :order => 'min DESC')
  end

  def minutes_point_thresholds
    self.point_thresholds.find(:all, :conditions => {:rel => "MINUTES"}, :order => 'min DESC')
  end

  # Creates the initial assesement used at registration and the final assessment used at the program end
  def create_evaluations
    initial_evaluation = self.evaluation_definitions.create!(:name => "Initial Assessment", :days_from_start => 0)
    program_end_evaluation = self.evaluation_definitions.create!(:name => "Program End Evaluation", :days_from_start => self.program_length - 1)

      # initial_evaluation.update_attributes(:is_liked_least_displayed => false, :is_liked_most_displayed => false)
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

  def as_json(options={})
    options[:meta] ||= false
    options = options.merge({:methods => ["current_date", "active_evaluation_definition_ids", "current_competition"]})
    promotion_obj = super(options)
    return promotion_obj
  end

  def milestone_goals
    milestones = self.badges.milestones.collect{|ms| [ms.id, ms.point_goal]}.inject({}) { |h, (id, pts)| h[id] = pts; h }
  end

  def active_evaluation_definition_ids
    return self.evaluation_definitions.reload.active.reload.collect{|ed|ed.id}
  end

  def clear_hes_cache
    ApplicationController.hes_cache_clear self.class.name.underscore.pluralize
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

  def clear_cache
    cache_key = "promotion_#{self.id}"
    Rails.cache.delete(cache_key)
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
        comp = @current_competition = competitions.find(:first,:conditions=>["enrollment_starts_on <= :today and :today <= enrollment_ends_on", {:today=>today}])
      else
        comp = @current_competition
      end
    end
    comp || competitions.find( :last, :conditions => [ "enrollment_starts_on <= :today", { :today => today } ] )
  end

end
