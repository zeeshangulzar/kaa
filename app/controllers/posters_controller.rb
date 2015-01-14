class PostersController < ApplicationController

  authorize :all, :user
  
  def index
    return HESResponder(@promotion.posters)
  end

  def show
    poster = Poster.find(params[:id]) rescue nil
    # TODO: what can users see about a poster? specifically, one they haven't yet unlocked
    return HESResponder("Poster", "NOT_FOUND") if !poster
    if poster.promotion.id == @current_user.promotion_id || @current_user.master?
      return HESResponder(poster)
    else
      return HESResponder("You may not view other promotions' posters.", "DENIED")
    end
  end

  def create
    poster = @promotion.posters.build(params[:poster])
    if poster.valid?
      Poster.transaction do
        poster.save!
      end
      return HESResponder(poster)
    else
      return HESResponder(poster.errors.full_messages, "ERROR")
    end
  end

  def update
    poster = Poster.find(params[:id]) rescue nil
    return HESResponder("Poster", "NOT_FOUND") if !poster
    Poster.transaction do
      poster.update_attributes(params[:poster])
    end
    if !poster.valid?
      return HESResponder(poster.errors.full_messages, "ERROR")
    else
      return HESResponder(poster)
    end
  end

  def destroy
    poster = Poster.find(params[:id]) rescue nil
    if !poster
      return HESResponder("Poster", "NOT_FOUND")
    elsif @current_user.master? && poster.destroy
      return HESResponder(poster)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end