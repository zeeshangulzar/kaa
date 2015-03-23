# Controller for handling all post requests
class PostsController < ApplicationController
  respond_to :json

  # Get the wallable before each request
  before_filter :get_wallable, :only => [:index, :create, :popular_posts, :recent_posts]

  authorize :index, :show, :create, :update, :destroy, :recent_posts, :popular_posts, :user

  # for the user that owns the post, any user to flag a post, and master users
  authorize :update, :user, lambda { |user, post, params|
    if params[:post].keys.size >= 1
      if params[:post].has_key?(:is_flagged)
        if params[:post][:is_flagged] == "false" || params[:post][:is_flagged] == false
          return user.role == "Master" || user.role == "Poster"
        elsif post.user_id == user.id
          return false
        else
          post_params = params.delete(:post)
          params[:post] = {:is_flagged => post_params[:is_flagged]}
          return true
        end
      end
    end
    return post.user_id == user.id || user.role == "Master" || user.role == "Poster"
  }

  # for the user that owns the post and master users
  authorize :destroy, lambda { |user, post, params| post.user_id == user.id || user.role == "Master" || user.role == "Poster" }

  authorize :flagged_posts, :popular_posts, :poster

  # Extra authorization parameters
  def authorization_parameters
    @post = Post.find_by_id(params[:id])
    [@post]
  end

  # Get the wallable or render an error, only on index or create
  #
  # @param [Integer] wallable id of the wall with posts
  # @param [String] wallable type of the wall with posts
  def get_wallable
    unless params[:wallable_id].nil? || params[:wallable_type].nil?
      @wallable = params[:wallable_type].singularize.camelcase.constantize.find(params[:wallable_id]) rescue nil
      if !@wallable
        return HESResponder(params[:wallable_type].singularize.camelcase, "NOT_FOUND")
      end
    else
      return HESResponder("Must pass wallable id and wallable_type", "ERROR")
    end
  end

  def index
    if @wallable.class == Post
      # parent is Post.. so just grab the replies..
      return HESResponder(@wallable.replies)
    else
      limit = params[:page_size].nil? ? 50 : params[:page_size].to_i
      offset = params[:offset].nil? ? 0 : params[:offset].to_i
      location_ids = []
      if !params[:location].nil?
        location_ids_submitted = params[:location].split(',')
        location_ids_submitted.each{|l_id|
          if l_id.is_i?
            location_ids << l_id.to_i
          end
        }
      end
      user_ids = (!params[:friends_only].nil? && params[:friends_only]) ? @current_user.friends.collect{|f|f.id} : []
      has_photo = (!params[:has_photo].nil? && (params[:has_photo] == 'true' || params[:has_photo] == true)) ? true : false
      conditions = {
        :offset       => offset,
        :limit        => limit,
        :user_ids     => user_ids,
        :location_ids => location_ids,
        :has_photo    => has_photo,
        :current_year => @promotion.current_date.year
      }

      count = Post.wall(@wallable, conditions, true).to_i

      posts = Post.wall(@wallable, conditions)

      response = {
        :data => posts,
        :meta => {
          :page_size => limit,
          :total_records => count
        }
      }

      if !posts.empty?
        if offset + limit < count.to_i
          response[:meta][:next] = url_replace(request.fullpath, :merge_query => {'offset' => offset + limit})
        end
        if offset - limit >= 0
          response[:meta][:prev] = url_replace(request.fullpath, :merge_query => {'offset' => offset - limit})
        end
      end
      return HESResponder(response)

    end
  end

  def recent_posts
    psize = params[:page_size].nil? ? 5 : params[:page_size]
    timestamp = params[:timestamp].nil? ? @promotion.current_date.to_time - 1.day : params[:timestamp].is_i? ? Time.at(params[:timestamp].to_i) : params[:timestamp]
    after = params[:after].nil? ? false : params[:after].to_i
    if after
      # get N posts immediately following params[:after]
      p = @wallable.posts.includes(:root_post).after(after).where("is_flagged <> 1").order("created_at ASC").limit(psize).reverse
    else
      p = @wallable.posts.includes(:root_post).where("created_at >= ? AND is_flagged <> 1", timestamp).order("created_at DESC").limit(psize)
    end

    p.each_with_index{|post,index|
      # remove posts where parent is deleted or flagged
      if !post.parent_post_id.nil?
        if post.parent_post.nil? || post.parent_post.is_flagged
          p.delete_at(index)
        end
      end
    }

    response = p.as_json(:methods => 'root_user')
    return HESResponder(response)
  end

  def popular_posts
    # Popular weight determined by: (reply_weight + like_weight) * days_old_weight
    @popular_posts = @wallable.posts.top.sort_by {|post| ((post.replies.size * HesPosts.reply_weight) + post.likes.size * HesPosts.like_weight) * post.days_old_weight}.reverse
    @popular_posts = @popular_posts[0..19]

    return HESResponder(@popular_posts)
  end

  def flagged_posts
    @flagged_posts = Post.where(:is_flagged => true)

    #respond_to do |format|
    #  format.json { render :json => @flagged_posts, :include => [:wallable, :user] }
    #end
    return HESResponder(@flagged_posts)
  end

  def show
    @post = Post.find(params[:id]) rescue nil
    if !@post
      return HESResponder("Post", "NOT_FOUND")
    end
    Post.transaction do
      @post.views = @post.views + 1
      @post.save!
    end
    return HESResponder(@post)
  end

  def create
    parent_obj = @wallable || @postable
    post = parent_obj.posts.build

    if parent_obj.class == Forum
      # Forum "topic" permissions
      if (@current_user.sub_promotion_coordinator_or_above? && parent_obj.location.promotion_id == @current_user.promotion_id) || @current_user.location_ids.include?(parent_obj.location_id) || @current_user.master?
        # good to post, was too difficult to write the opposite of these tests, hence the else..
      else
        return HESResponder("Cannot post forum topic.", "DENIED")
      end
    elsif parent_obj.class == Post
      post.parent_post_id = parent_obj.id
      post.depth = parent_obj.depth + 1
    end

    post.user_id = @current_user.id
    post.update_attributes(params[:post])
    if !post.valid?
      return HESResponder(post.errors.full_messages, "ERROR")
    end
    post.reload
    $redis.publish('newPostCreated', post.to_json)
    return HESResponder(post)
  end

  def update
    @post = Post.find(params[:id]) rescue nil
    return HESResponder("Post", "NOT_FOUND") if !@post
    
    if @post.user_id != @current_user.id && !@current_user.location_coordinator_or_above?
      params[:post] = {:is_flagged => params[:post][:is_flagged]}
      if !params[:post][:is_flagged].nil? && params[:post][:is_flagged] == true
        params[:post][:flagged_by] = @current_user.id
      end
    end

    @post.update_attributes(params[:post])
    if !@post.valid?
      return HESResponder(@post.errors.full_messages, "ERROR")
    end
    return HESResponder(@post)
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    return HESResponder(@post)
  end
end
