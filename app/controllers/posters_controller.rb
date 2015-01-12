class PostersController < ApplicationController

  authorize :all, :user
  
  def index
    return HESResponder(@promotion.posters)
  end

  def show
    poster = Poster.find(params[:id]) rescue nil
    # TODO: what can users see about a poster? specifically, one they haven't yet unlocked
    return HESResponder2("Poster", "NOT_FOUND") if !poster
    if poster.promotion.id == @current_user.promotion_id || @current_user.master?
      return HESResponder2(poster)
    else
      return HESResponder2("You may not view other promotions' posters.", "DENIED")
    end
  end

  def create
    poster = @promotion.posters.build(params[:poster])
    if poster.valid?
      Poster.transaction do
        poster.save!
      end
      return HESResponder2(poster)
    else
      return HESResponder2(poster.errors.full_messages, "ERROR")
    end
  end

  def update
    poster = Poster.find(params[:id]) rescue nil
    return HESResponder2("Poster", "NOT_FOUND") if !poster
    Poster.transaction do
      poster.update_attributes(params[:poster])
    end
    if !poster.valid?
      return HESResponder2(poster.errors.full_messages, "ERROR")
    else
      return HESResponder2(poster)
    end
  end

  def destroy
    poster = Poster.find(params[:id]) rescue nil
    if !poster
      return HESResponder2("Poster", "NOT_FOUND")
    elsif @current_user.master? && poster.destroy
      return HESResponder2(poster)
    else
      return HESResponder2("Error deleting.", "ERROR")
    end
  end

end