# Controller for handling all like requests
class LikesController < ApplicationController
  # Get the user before each request
  before_filter :get_likeable

  authorize :index, :show, :destroy, :master
  authorize :user_like_show, :user_like_create, :user_like_destroy, :create, :user

  # for the user that created the like
  authorize :destroy, lambda{ |user, like, params| params[:id].nil? || like.user_id == user.id || user.role == "Master"}
  
  # Extra authorization parameters
  def authorization_parameters
    @like = Like.find_by_id(params[:id])
    [@like]
  end

  def get_likeable
    if params[:likeable_id] && params[:likeable_type]
      @likeable = params[:likeable_type].singularize.camelcase.constantize.find(params[:likeable_id])
    elsif params[:action] == 'create'
      render :json => { :errors => ["Must pass likeable id"] }, :status => :unprocessable_entity 
    end
  end

  def index
    @likes = @likeable ? @likeable.likes : params[:likeable_type] ? @current_user.likes.where(:likeable_type => params[:likeable_type]) : @current_user.likes
    return HESResponder(@likes)
  end

  def show
    @like = Like.find(params[:id])
    return HESResponder(@like)
  end

  def create
    if !@likeable.likes.where(:user_id => @current_user.id).empty?
      return HESResponder("You may only like a #{@likeable.class.name.to_s.downcase} once.", "ERROR")
    end
    @like = @current_user.likes.build
    @like.likeable_id = @likeable.id
    @like.likeable_type = @likeable.class.to_s
    @like.save!
    return HESResponder(@like)
  end

  def destroy
    @like = params[:id].nil? ? @likeable.likes.where(:user_id => get_user.id).first : Like.find(params[:id])
    @like.destroy
    return HESResponder(@like)
  end


  def user_like_show
    like = false
    if @likeable
      like = @likeable.likes.where(:user_id => @current_user.id).first if !@likeable.likes.where(:user_id => @current_user.id).empty?
      return HESResponder("like", "NOT_FOUND") if !like
      return HESResponder(like)
    else
      return HESResponder("likeable doesn't exist.", "ERROR")
    end
  end

  def user_like_create
    like = false
    if @likeable
      like = @likeable.likes.where(:user_id => @current_user.id).first if !@likeable.likes.where(:user_id => @current_user.id).empty?
      if !like
        like = @current_user.likes.build
        like.likeable_id = @likeable.id
        like.likeable_type = @likeable.class.name.to_s
        like.save
      end
      return HESResponder(like)
    else
      return HESResponder("likeable doesn't exist.", "ERROR")
    end
  end

  def user_like_destroy
    like = false
    if @likeable
      like = @likeable.likes.where(:user_id => @current_user.id).first if !@likeable.likes.where(:user_id => @current_user.id).empty?
      if !like
        return HESResponder("like", "NOT_FOUND") if !like
      else
        like.destroy
        return HESResponder(like)
      end
    else
      return HESResponder("likeable doesn't exist.", "ERROR")
    end
  end
  
end