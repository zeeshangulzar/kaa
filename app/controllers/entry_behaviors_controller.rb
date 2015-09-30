class EntryBehaviorsController < ApplicationController
  authorize :all, :user

  def index
    unless params[:entry_id].nil?
      @entry_behaviors = @current_user.entries.find(params[:entry_id]).entry_behaviors
      return HESResponder(@entry_behaviors)
    else
      return HESResponder("Must pass entry id", "ERROR")
    end
  end

  def show
    @entry_behavior = EntryBehavior.find(params[:id])
    return HESResponder(@entry_behavior)
  end

  def create
    # Lets us lazy create entries by just passing the date the entry is supposed to be logged
    if params[:entry_behavior][:entry_id].nil?
      if params[:logged_on]
        entry = @target_user.entries.find_or_create_by_logged_on(params[:logged_on])
        params[:entry_behavior][:entry_id] = entry.id
      else
        return HESResponder("Must pass logged on date for entry or entry id", "ERROR")
      end
    end
    
    @entry_behavior = EntryBehavior.create(params[:entry_behavior])
    return HESResponder(@entry_behavior)
  end

  def update
    @entry_behavior = EntryBehavior.find(params[:id])
    @entry_behavior.update_attributes(params[:entry_behavior])
    return HESResponder(@entry_behavior)
  end

  def destroy
    @entry_behavior = EntryBehavior.find(params[:id])
    @entry_behavior.destroy
    return HESResponder(@entry_behavior)
  end
end