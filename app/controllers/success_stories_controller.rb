class SuccessStoriesController < ApplicationController
  authorize :all, :user
  wrap_parameters :success_story
  
  def index
    success_stories = @promotion.success_stories.active
    if @current_user.coordinator? && !params[:status].nil?
      case params[:status]
        when 'all'
          success_stories = @promotion.success_stories
        when 'featured'
          success_stories = @promotion.success_stories.active.featured
        else
          if SuccessStory::STATUS.stringify_keys.keys.include?(params[:status])
            # ?status=[unseen,accepted,etc.]
            success_stories = @promotion.success_stories.send(params[:status])
          elsif params[:status].is_i? && SuccessStory::STATUS.values.include?(params[:status].to_i)
            # ?status=[0,1,2,3,4]
            success_stories = @promotion.success_stories.send(SuccessStory::STATUS.index(params[:status].to_i).to_s)
          else
            return HESResponder("No such status.", "ERROR")
          end
      end
    end
    return HESResponder(success_stories)
  end

  def featured
    return HESResponder(@promotion.success_stories.active.featured)
  end

  def show
    success_story = SuccessStory.find(params[:id]) rescue nil
    return HESResponder("Success story", "NOT_FOUND") if !success_story
    if @current_user.coordinator? || (success_story.promotion_id == @current_user.promotion_id && success_story.active)
      return HESResponder(success_story)
    else
      return HESResponder("You may not view this.", "DENIED")
    end
  end

  def create
    params[:user_id] = @current_user.id
    success_story = @promotion.success_stories.build(params[:success_story])
    if success_story.valid?
      SuccessStory.transaction do
        success_story.save!
      end
      return HESResponder(success_story)
    else
      return HESResponder(success_story.errors.full_messages, "ERROR")
    end
  end

  def update
    success_story = SuccessStory.find(params[:id]) rescue nil
    return HESResponder("Success story", "NOT_FOUND") if !success_story
    SuccessStory.transaction do
      success_story.update_attributes(params[:success_story])
    end
    if !success_story.valid?
      return HESResponder(success_story.errors.full_messages, "ERROR")
    else
      return HESResponder(success_story)
    end
  end

  def destroy
    success_story = SuccessStory.find(params[:id]) rescue nil
    if !success_story
      return HESResponder("Success story", "NOT_FOUND")
    elsif @current_user.master? && success_story.destroy
      return HESResponder(success_story)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end