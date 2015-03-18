class EntriesController < ApplicationController

  authorize :all, :user
  
  # Gets the list of entries for an team instance
  #
  # @return [Array] of all entries
  #
  # [URL] /entries [GET]
  #  [200 OK] Successfully retrieved Entry Array object
  #   # Example response
  #   [{
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }]
  def index
    return HESResponder("You can't view other users' events.", "DENIED") if @target_user.id != @current_user.id && !@current_user.master?
    options = {}
    options[:start] = params[:start].nil? ? @promotion.starts_on : (params[:start].is_i? ? Time.at(params[:start].to_i).to_date : params[:start].to_date)
    options[:end] = params[:end].nil? ? @promotion.current_date : (params[:end].is_i? ? Time.at(params[:end.to_i]).to_date : params[:end].to_date)
    if !params[:recorded_on].nil?
      options[:recorded_on] = params[:end].is_i? ? Time.at(params[:end.to_i]).to_date : params[:end].to_date
    end
    entries = (!@target_user.entries.available(options).empty?) ? @target_user.entries.available(options) : []
    
    # TODO: this still isn't fast enough
    # need to figure out a quick method of getting attrs of behaviors, etc.
    entries_array = []
    entries.each_with_index{|entry,index|
      
      behaviors_array = []
      entry.entry_behaviors.each_with_index{|eb,eb_index|
        behavior_hash = {
          :id           => eb.id,
          :behavior_id  => eb.behavior_id,
          :value        => eb.value
        }
        behaviors_array[eb_index] = behavior_hash
      }
      
      activities_array = []
      entry.entry_exercise_activities.each_with_index{|eea,eea_index|
        activity_hash = {
          :id => eea.id,
          :exercise_activity_id => eea.exercise_activity_id,
          :value                => eea.value
        }
        activities_array[eea_index] = activity_hash
      }

      entry_hash = {
        :id                           => entry.id,
        :recorded_on                  => entry.recorded_on,
        :is_recorded                  => entry.is_recorded,
        :exercise_minutes             => entry.exercise_minutes,
        :exercise_steps               => entry.exercise_steps,
        :exercise_points              => entry.exercise_points,
        :timed_behavior_points        => entry.timed_behavior_points,
        :challenge_points             => entry.challenge_points,
        :url                          => "/entries/" + entry.id.to_s,
        :notes                        => entry.notes,
        :entry_behaviors              => behaviors_array,
        :entry_exercise_activities    => activities_array,
        :goal_steps                   => entry.goal_steps,
        :goal_minutes                 => entry.goal_minutes,
        :updated_at                   => entry.updated_at,
        :manually_recorded            => entry.manually_recorded
      }
      entries_array[index] = entry_hash
    }
    return HESResponder(entries_array, "OK", 0)
  end

  # Gets a single entry for a team
  #
  # @example
  #  #GET /entries/1
  #
  # @param [Integer] id of the entry
  # @return [Entry] that matches the id
  #
  # [URL] /entries/1 [GET]
  #  [200 OK] Successfully retrieved Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }
  def show
    @entry = Entry.find(params[:id]) rescue nil
    return HESResponder("Entry", "NOT_FOUND") if !@entry
    if @entry.user.id == @current_user.id || @current_user.master?
      return HESResponder(@entry)
    else
      return HESResponder("You may not view other users' entries.", "DENIED")
    end
  end

  # Creates a single entry
  #
  # @example
  #  #POST /entries/1
  #  {
  #    exercise_minutes: 45,
  #    notes: "Eliptical machine while reading Fitness magazine"
  #  }
  # @return [Entry] that was just created
  #
  # [URL] /entries [POST]
  #  [201 CREATED] Successfully created Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_logged": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #   }
  def create
    ex_activities = params[:entry].delete(:entry_exercise_activities) || []
    behaviors = params[:entry].delete(:entry_behaviors) || []
    @entry = @target_user.entries.find_by_recorded_on(params[:entry][:recorded_on]) || @target_user.entries.build(params[:entry])
    @entry.assign_attributes(params[:entry])
    if !@entry.valid?
      return HESResponder(@entry.errors.full_messages, "ERROR")
    else
      Entry.transaction do
        @entry.save!
        #create exercise activites
        ex_activities.each do |hash|
          @entry.entry_exercise_activities.create(scrub(hash, EntryExerciseActivity))
        end

        #TODO: Test entry activities
        behaviors.each do |hash|
          @entry.entry_behaviors.create(scrub(hash, EntryBehavior))
        end

        @entry.save!
      end
      return HESResponder(@entry)
    end
    # see app/mailers/go_mailer.rb
    # GoMailer.dummy_email(@entry).deliver!
    # see app/jobs/dummy_job.rb
    # Resque.enqueue(DummyJob,@entry.id)
  end

  # Updates a single entry
  #
  # @example
  #  #PUT /entries/1
  #  {
  #    exercise_minutes: 45,
  #    notes: "Eliptical machine while reading Fitness magazine"
  #  }
  #
  # @param [Integer] id of the entry
  # @return [Entry] that was just updated
  #
  # [URL] /entries [PUT]
  #  [202 ACCEPTED] Successfully updated Entry object
  #   # Example response
  #   {
  #    "user_id": 1,
  #    "exercise_minutes": 45,
  #    "is_recorded": true
  #    "recorded_on": "2012-11-21"
  #    "notes": "Eliptical machine while reading Fitness magazine"
  #    "entry_activities" : [{}]
  #    "entry_exercise_activities" : [{}]
  #   }
  def update
    @entry = @target_user.entries.find(params[:id])
    if @entry.user.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit this entry.", "DENIED")
    end
    return HESResponder(@entry.errors.full_messages, "ERRROR") if !@entry.valid?
    Entry.transaction do
      entry_ex_activities = params[:entry].delete(:entry_exercise_activities)
      if !entry_ex_activities.nil?
        
        ids = entry_ex_activities.nil? ? [] : entry_ex_activities.map{|x| x[:id]}
        remove_activities = @entry.entry_exercise_activities.reject{|x| ids.include? x.id}

        remove_activities.each do |act|
          # Remove from array and delete from db
           @entry.entry_exercise_activities.delete(act).first.destroy
        end

        entry_ex_activities.each do |entry_ex_act|
          if entry_ex_act[:id]
            eea = @entry.entry_exercise_activities.detect{|x|x.id==entry_ex_act[:id].to_i}
            eea.update_attributes(scrub(entry_ex_act, EntryExerciseActivity))
          else
            @entry.entry_exercise_activities.create(scrub(entry_ex_act, EntryExerciseActivity))
          end
        end
      end

      entry_behaviors = params[:entry].delete(:entry_behaviors)
      if !entry_behaviors.nil?
        ids = entry_behaviors.nil? ? [] : entry_behaviors.map{|x| x[:id]}
        remove_behaviors = @entry.entry_behaviors.reject{|x| ids.include? x.id}

        remove_behaviors.each do |act|
          @entry.entry_behaviors.delete(act).first.destroy
        end

         entry_behaviors.each do |entry_behavior|
          if entry_behavior[:id]
            eb = @entry.entry_behaviors.detect{|x|x.id==entry_behavior[:id].to_i}
            eb.update_attributes(scrub(entry_behavior, EntryBehavior))
          else
            @entry.entry_behaviors.create(scrub(entry_behavior, EntryBehavior))
          end
        end
      end 

      @entry.assign_attributes(scrub(params[:entry], Entry))
      @entry.save!
    end
    return HESResponder(@entry)
  end

  def aggregate
    year = !params[:year].nil? ? params[:year].to_i : @promotion.current_date.year
    return HESResponder(Entry.aggregate({:year => year, :user_id => @current_user.id}), "OK", 0)
  end

end
