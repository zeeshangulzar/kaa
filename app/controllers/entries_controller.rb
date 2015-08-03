class EntriesController < ApplicationController

  authorize :all, :user
  
  def index
    return HESResponder("You can't view other users' entries.", "DENIED") if @target_user.id != @current_user.id && !@current_user.master?
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
        :behavior_points              => entry.behavior_points,
        :gift_points                  => entry.gift_points,
        :url                          => "/entries/" + entry.id.to_s,
        :notes                        => entry.notes,
        :entry_behaviors              => behaviors_array,
        :entry_gifts                  => gifts_array,
        # :entry_exercise_activities    => activities_array,
        :goal_steps                   => entry.goal_steps,
        :goal_minutes                 => entry.goal_minutes,
        :updated_at                   => entry.updated_at,
        :manually_recorded            => entry.manually_recorded
      }
      entries_array[index] = entry_hash
    }
    return HESResponder(entries_array, "OK", 0)
  end

  def show
    @entry = Entry.find(params[:id]) rescue nil
    return HESResponder("Entry", "NOT_FOUND") if !@entry
    if @entry.user.id == @current_user.id || @current_user.master?
      return HESResponder(@entry)
    else
      return HESResponder("You may not view other users' entries.", "DENIED")
    end
  end

  def create
    entries = []
    entries_sent = !params[:entries].nil? && params[:entries].is_a?(Array) ? params[:entries] : [params[:entry]]
    Entry.transaction do
      entries_sent.each{ |entry|
        entries << create_or_update(entry)
      }
    end
    return HESResponder(entries)
  end

  def update
    entries = []
    entries_sent = !params[:entries].nil? && params[:entries].is_a?(Array) ? params[:entries] : [params[:entry]]
    Entry.transaction do
      entries_sent.each{ |entry|
        entries << create_or_update(entry)
      }
    end
    return HESResponder(entries)
  end

  def aggregate
    year = !params[:year].nil? ? params[:year].to_i : @promotion.current_date.year
    return HESResponder(Entry.aggregate({:year => year, :user_id => @current_user.id}), "OK", 0)
  end

  def create_or_update(entry_params)
    entry = entry_id = nil
    if !entry_params[:id].nil?
      entry = @target_user.entries.find(entry_params[:id])
      return HESResponder("Entry", "NOT_FOUND") if !entry
      entry_id = entry.id
    end
    if ((entry && entry.user_id != @current_user.id) || (entry_params[:user_id] && entry_params[:user_id] != @current_user.id)) && !@current_user.master?
      return HESResponder("You may only edit your entries.", "DENIED")
    end

    entry_exercise_activities = entry_params.delete(:entry_exercise_activities)
    entry_behaviors = entry_params.delete(:entry_behaviors)
    entry_gifts = entry_params.delete(:entry_gifts)

    if !entry
      entry = @target_user.entries.find_by_recorded_on(entry_params[:recorded_on]) || @target_user.entries.build(entry_params)
    end
    entry.assign_attributes(scrub(entry_params, Entry))
    return HESResponder(entry.errors.full_messages, "ERROR") if !entry.valid?

    Entry.transaction do
      entry.save! if !entry_id
      if !entry_exercise_activities.nil?
        entry_exercise_activity_ids = entry_exercise_activities.map{|x| x[:id]}
        remove_activities = entry.entry_exercise_activities.reject{|x| entry_exercise_activity_ids.include?(x.id)}
        remove_activities.each do |activity|
          # Remove from array and delete from db
           entry.entry_exercise_activities.delete(act).first.destroy
        end
        entry_exercise_activities.each do |entry_exercise_activity|
          hash = scrub(entry_exercise_activity, EntryExerciseActivity)
          if entry_exercise_activity[:exercise_activity_id] && entry_exercise_activity[:value] && entry_exercise_activity[:exercise_activity_id].to_s.is_i? && entry_exercise_activty[:value].to_s.is_i?
            if entry_exercise_activity[:id]
              eea = entry.entry_exercise_activities.detect{|x|x.id == entry_exercise_activity[:id].to_i}
              eea.update_attributes(hash)
            else
              entry.entry_exercise_activities.create(hash)
            end
          end
        end
      end

      if !entry_behaviors.nil?
        entry_behavior_ids = entry_behaviors.map{|x| x[:id]}
        remove_behaviors = entry.entry_behaviors.reject{|x| entry_behavior_ids.include?(x.id)}
        remove_behaviors.each do |behavior|
          # Remove from array and delete from db
           entry.entry_behaviors.delete(behavior).first.destroy
        end
        entry_behaviors.each do |entry_behavior|
          hash = scrub(entry_behavior, EntryBehavior)
          if entry_behavior[:behavior_id] && entry_behavior[:value] && entry_behavior[:behavior_id].to_s.is_i? && entry_behavior[:value].to_s.is_i?
            if entry_behavior[:id]
              eb = entry.entry_behaviors.detect{|x|x.id == entry_behavior[:id].to_i}
              eb.update_attributes(hash)
            else
              entry.entry_behaviors.create(hash)
            end
          end
        end
      end

      if !entry_gifts.nil?
        entry_gift_ids = entry_gifts.map{|x| x[:id]}
        remove_gifts = entry.entry_gifts.reject{|x| entry_gift_ids.include?(x.id)}
        remove_gifts.each do |gift|
          # Remove from array and delete from db
           entry.entry_gifts.delete(gift).first.destroy
        end
        entry_gifts.each do |entry_gift|
          hash = scrub(entry_gift, EntryGift)
          if entry_gift[:gift_id] && entry_gift[:value] && entry_gift[:gift_id].to_s.is_i? && entry_gift[:value].to_s.is_i?
            if entry_gift[:id]
              eg = entry.entry_gifts.detect{|x|x.id == entry_gift[:id].to_i}
              eg.update_attributes(hash)
            else
              entry.entry_gifts.create(hash)
            end
          end
        end
      end

      entry.save!

    end # transaction

    return entry

  end

  private :create_or_update

end
