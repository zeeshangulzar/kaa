class SuccessStoriesController < ApplicationController
  authorize :all, :user
  wrap_parameters :success_story
  
  def index
    return HESResponder2(@promotion.success_stories.active)
  end

  def featured
    return HESResponder2(@promotion.success_stories.active.featured)
  end

  def show
    success_story = SuccessStory.find(params[:id]) rescue nil
    return HESResponder2("Success story", "NOT_FOUND") if !success_story
    # TODO: privacy stuff here.. same promotion?
    if (success_story.promotion_id == @current_user.promotion_id && success_story.active) || @current_user.master?
      return HESResponder2(success_story)
    else
      return HESResponder2("You may not view this.", "DENIED")
    end
  end

  def create
    success_story = @promotion.success_stories.build(params[:success_story])
    if success_story.valid?
      SuccessStory.transaction do
        success_story.save!
      end
      return HESResponder2(success_story)
    else
      return HESResponder2(success_story.errors.full_messages, "ERROR")
    end
  end

  def update
    success_story = SuccessStory.find(params[:id]) rescue nil
    return HESResponder2("Success story", "NOT_FOUND") if !success_story
    SuccessStory.transaction do
      success_story.update_attributes(params[:success_story])
    end
    if !success_story.valid?
      return HESResponder2(success_story.errors.full_messages, "ERROR")
    else
      return HESResponder2(success_story)
    end
  end

  def destroy
    success_story = SuccessStory.find(params[:id]) rescue nil
    if !success_story
      return HESResponder2("Success story", "NOT_FOUND")
    elsif @current_user.master? && success_story.destroy
      return HESResponder2(success_story)
    else
      return HESResponder2("Error deleting.", "ERROR")
    end
  end

end