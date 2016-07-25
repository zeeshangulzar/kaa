# Controller for handling all rating requests
class RatingsController < ApplicationController

  # Get the user before each request
  before_filter :get_rateable

  authorize :create, :user_rating_show, :user_rating_create, :user_rating_destroy, :user
  authorize :index, :show, :coordinator
  
  # Extra authorization parameters
  def authorization_parameters
    @rating = Rating.find_by_id(params[:id])
    [@rating]
  end

  def get_rateable
    if params[:rateable_id] && params[:rateable_type]
      @rateable = params[:rateable_type].singularize.camelcase.constantize.find(params[:rateable_id]) rescue nil
      return HESResponder("Rateable", "NOT_FOUND") if !@rateable || !@rateable.respond_to?('ratings')
    elsif params[:action] == 'create'
      return HESResponder("Must pass rateable id", "ERROR")
    end
  end

  def index
    ratings = @rateable ? @rateable.ratings : params[:rateable_type] ? @current_user.ratings.where(:rateable_type => params[:rateable_type]) : @current_user.ratings
    if !@current_user.master? && !@current_user.poster?
      ratings = ratings.includes(:user).where("users.promotion_id = #{@promotion.id}")
    end
    return HESResponder(ratings)
  end

  def show
    rating = @rateable.ratings.find(params[:id]) rescue nil
    return HESResponder("Rating", "NOT_FOUND") if !rating
    if !@current_user.master? && !@current_user.poster? && @current_user.id != rating.user_id
      return HESResponder("Denied.", "DENIED")
    end
    return HESResponder(rating)
  end

  def create
    if @rateable.ratings.where(:user_id => @current_user.id).empty?
      return HESResponder("Denied.", "DENIED") if @rateable.respond_to?('promotion_id') && @rateable.promotion_id != @current_user.promotion_id
      rating = @current_user.ratings.build
      rating.rateable_id = @rateable.id
      rating.rateable_type = @rateable.class.name.to_s
      rating.score = !params[:score].nil? && (Rating::MIN_SCORE..Rating::MAX_SCORE).include?(params[:score].to_i) ? params[:score].to_i : Rating::MAX_SCORE
      Rating.transaction do
        rating.save!
      end
      return HESResponder(rating.errors.full_messages, "ERROR") if !rating.valid?
      return HESResponder(rating)
    else
      return HESResponder("You may only rate a #{@rateable.class.name.to_s.downcase} once", "ERROR")
    end
  end

  def destroy
    rating = (params[:id].nil? ? @rateable.ratings.where(:user_id => @current_user.id).first : @current_user.ratings.find(params[:id])) rescue nil
    return HESResponder("Rating", "NOT_FOUND") if !rating
    rating.destroy
    return HESResponder(rating)
  end

  def user_rating_show
    rating = false
    if @rateable
      rating = @rateable.ratings.where(:user_id => @current_user.id).first if !@rateable.ratings.where(:user_id => @current_user.id).empty?
      return HESResponder("Rating", "NOT_FOUND") if !rating
      return HESResponder(rating)
    else
      return HESResponder("Rateable doesn't exist.", "ERROR")
    end
  end

  def user_rating_create
    rating = false
    if @rateable
      rating = @rateable.ratings.where(:user_id => @current_user.id).first if !@rateable.ratings.where(:user_id => @current_user.id).empty?
      if !rating
        rating = @current_user.ratings.build
        rating.rateable_id = @rateable.id
        rating.rateable_type = @rateable.class.name.to_s
        rating.score = !params[:score].nil? && (Rating::MIN_SCORE..Rating::MAX_SCORE).include?(params[:score].to_i) ? params[:score].to_i : Rating::MAX_SCORE
      else
        rating.score = !params[:score].nil? && (Rating::MIN_SCORE..Rating::MAX_SCORE).include?(params[:score].to_i) ? params[:score].to_i : Rating::MAX_SCORE
      end
      Rating.transaction do
        rating.save!
      end
      return HESResponder(rating.errors.full_messages, "ERROR") if !rating.valid?
      return HESResponder(rating)
    else
      return HESResponder("Rateable doesn't exist.", "ERROR")
    end
  end

  def user_rating_destroy
    rating = false
    if @rateable
      rating = @rateable.ratings.where(:user_id => @current_user.id).first if !@rateable.ratings.where(:user_id => @current_user.id).empty?
      if !rating
        return HESResponder("Rating", "NOT_FOUND") if !rating
      else
        rating.destroy
        return HESResponder(rating)
      end
    else
      return HESResponder("Rateable doesn't exist.", "ERROR")
    end
  end

end
