class Promotion < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :subdomain, :customized_files, :theme, :public

  attr_privacy :starts_on, :steps_point_thresholds, :minutes_point_thresholds, :program_length, :behaviors, :exercise_activities, :challenges, :static_tiles, :dynamic_tiles, :any_user

  belongs_to :organization

  has_many :users
  has_many :behaviors
  has_many :exercise_activities
  has_many :point_thresholds, :as => :pointable, :order => 'min DESC'
  has_many :posters, :order => 'visible_date ASC'
  has_many :success_stories

  has_many :challenges
  has_many :suggested_challenges

  has_many :locations, :order => "parent_location_id, sequence", :dependent => :destroy

  has_wall
  has_evaluations

  after_create :create_evaluations
  after_update :update_evaluations, :if => lambda { self.program_length != self.program_length_was }

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
  

  def nested_locations
    nested = []
    self.locations.each do |location|
      if location.top?
        location = self.get_kids(location)
        nested.push(location)
      end
    end
    return nested
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

end
