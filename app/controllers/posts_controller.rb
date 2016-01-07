# Controller for handling all post requests
class PostsController < ApplicationController
  respond_to :json

  # Get the wallable before each request
  before_filter :get_wallable

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
      if !@current_user.master? && !@current_user.poster?
        if @wallable.class == Promotion && @wallable.id != @current_user.promotion_id
          return HESResponder("Denied.", "DENIED")
        elsif @wallable.class == Team && (!@current_user.current_team || @current_user.current_team.id != @wallable.id)
          return HESResponder("Denied.", "DENIED")
        elsif @wallable.respond_to?('promotion_id') && @wallable.promotion_id != @current_user.promotion_id
          return HESResponder("Denied.", "DENIED")
        elsif @wallable.respond_to?('wallable') && !@wallable.wallable.nil? && @wallable.wallable.class == Promotion && @wallable.wallable.id != @current_user.promotion_id
          return HESResponder("Denied.", "DENIED")
        end
      end
    else
      @wallable = @promotion
    end
  end

  def index
    if @wallable.class == Post
      # parent is Post.. so just grab the replies..
      return HESResponder(@wallable.posts)
    elsif [Promotion].include?(@wallable.class)
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

      user_ids = []
      if !params[:user_id].nil? && params[:user_id].is_i?
        user_ids = [params[:user_id].to_i]
      end

      has_photo = (!params[:has_photo].nil? && (params[:has_photo] == 'true' || params[:has_photo] == true)) ? true : false
      flagged_only = (!params[:flagged].nil? && (params[:flagged] == 'true' || params[:flagged] == true)) ? true : false
      by_popularity = (!params[:by_popularity].nil? && (params[:by_popularity] == 'true' || params[:by_popularity] == true)) ? true : false
      query = (!params[:query].nil? && !params[:query].strip.empty?) ? params[:query] : nil

      conditions = {
        :offset        => offset,
        :limit         => limit,
        :user_ids      => user_ids,
        :location_ids  => location_ids,
        :has_photo     => has_photo,
        :flagged_only  => flagged_only,
        :query         => query,
        :by_popularity => by_popularity
      }

      count = Post.wall(@wallable, conditions, true).to_i
      reply_count_hash = nil
      if params[:reply_count] && params[:reply_count].to_i == 1
        reply_count_hash = {:reply_count => Post.wall(@wallable, conditions, true, true).to_i}
      end
      
      posts = Post.wall(@wallable, conditions)

      response = {
        :data => posts,
        :meta => ApplicationController::meta(request, posts, offset, limit, count, reply_count_hash)
      }
      return HESResponder(response)
    else
      # not the wall, not a post.. grab posts
      has_photo = (!params[:has_photo].nil? && (params[:has_photo] == 'true' || params[:has_photo] == true)) ? true : false
      within_promotion = true # TODO: make some sort of switch for master/poster to see all posts regardless of promotion
      if within_promotion
        posts = has_photo ? @wallable.posts.includes(:user).where("`posts`.`photo` IS NOT NULL AND `users`.`promotion_id` = #{@promotion.id}") : @wallable.posts.top.where("`users`.`promotion_id` = #{@promotion.id}")
      else
        posts = has_photo ? @wallable.posts.where("photo IS NOT NULL") : @wallable.posts.top
      end
      return HESResponder(posts)
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
      post.attach('root_user', post.root_user)
      # remove posts where parent is deleted or flagged
      if !post.parent_post_id.nil?
        if post.parent_post.nil? || post.parent_post.is_flagged
          p.delete_at(index)
        end
      end
    }

    return HESResponder(p)
  end

  def popular_posts
    # Popular weight determined by: (reply_weight + like_weight) * days_old_weight
    @popular_posts = @wallable.posts.top.sort_by {|post| ((post.posts.size * HesPosts.reply_weight) + post.likes.size * HesPosts.like_weight) * post.days_old_weight}.reverse
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
    if @current_user.poster? || @current_user.master?
      post = Post.find(params[:id]) rescue nil
    else
      post = @wallable.posts.find(params[:id]) rescue nil
    end
    if !post
      return HESResponder("Post", "NOT_FOUND")
    end
    if !@current_user.poster? && !@current_user.master?
      Post.transaction do
        post.views = post.views + 1
        post.save!
      end
    end
    return HESResponder(post)
  end

  def create
    parent_obj = @wallable || @postable
    post = parent_obj.posts.build

    if parent_obj.class == Post
      post.parent_post_id = parent_obj.id
      post.depth = parent_obj.depth + 1
    end

    post.user_id = @current_user.id
    post.update_attributes(params[:post])
    if !post.valid?
      return HESResponder(post.errors.full_messages, "ERROR")
    end
    post.reload
    channel = (parent_obj.class == Team) ? 'newTeamPostCreated' : 'newPostCreated'
    $redis.publish(channel, post.to_json)
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
