# Controller for handling all rating requests
class RatingsController < ApplicationController
  respond_to :json

  # Get the user before each request
  before_filter :get_rateable, :only => [:index, :create, :destroy]

  authorize :create, :user
  authorize :index, :show, :coordinator
  
  # Extra authorization parameters
  def authorization_parameters
    @rating = Rating.find_by_id(params[:id])
    [@rating]
  end

  def get_rateable
    if params[:rateable_id] && params[:rateable_type]
      @rateable = params[:rateable_type].singularize.camelcase.constantize.find(params[:rateable_id])
    elsif params[:action] == 'create'
      return HESResponder("Must pass rateable id", "ERROR")
    end
  end

  def index
    @ratings = @rateable ? @rateable.ratings : params[:rateable_type] ? @current_user.ratings.where(:rateable_type => params[:rateable_type]) : @current_user.ratings
    return HESResponder(@ratings)
  end

  def show
    @rating = Rating.find(params[:id])
    return HESResponder(@rating)
  end

  def create
    if @rateable.ratings.where(:user_id => @current_user.id).empty?
      @rating = @current_user.ratings.build
      @rating.rateable_id = @rateable.id
      @rating.rateable_type = @rateable.class.name.to_s
      @rating.score = !params[:score].nil? && (Rating::MIN_SCORE..Rating::MAX_SCORE).include?(params[:score].to_i) ? params[:score].to_i : Rating::MAX_SCORE
      @rating.save
      return HESResponder(@rating)
    else
      return HESResponder("You may only rate a #{@rateable.class.name.to_s.downcase} once", "ERROR")
    end
  end

  def destroy
    @rating = params[:id].nil? ? @rateable.ratings.where(:user_id => @current_user.id).first : Rating.find(params[:id])
    @rating.destroy
    return HESResponder(@rating)
  end
end
