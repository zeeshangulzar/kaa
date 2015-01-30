# Controller for handling all post requests
class PostsController < ApplicationController
  respond_to :json

  # Get the wallable before each request
  before_filter :get_wallable, :only => [:index, :create, :popular_posts]


  authorize :index, :show, :create, :update, :destroy, :user

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
      @wallable = params[:wallable_type].singularize.camelcase.constantize.find(params[:wallable_id])
    else
      return HESResponder("Must pass wallable id and wallable_type", "ERROR")
    end
  end


  # Gets the list of posts for an wallable instance
  #
  # @url [GET] /promotions/1/posts
  # @authorize User
  # @param [Integer] max_id The max id of posts to fetch
  # @param [Integer] since_id The first id of posts to fetch
  # @param [Integer] page The page to fetch for the posts
  # @return [Array<Post>] Array of all posts
  #
  # [URL] /:wallable_type/:wallable_id/posts [GET]
  #  [200 OK] Successfully retrieved Posts Array object
  #   # Example response
  #   {
  #     "page": 1,
  #     "post_count": 20,
  #     "reply_count": 5,
  #     "next_page_url": "http://api.hesapps.com/promotions/54/posts?format=json&max_id=40&page=2",
  #     "posts": [{
  #       "id": 1,
  #       "content": "Love posting on this wall!!!!",
  #       "user_id": 1,
  #       "postable_id": 1,
  #       "postable_type": "Recipe",
  #       "category": "Nutrition",
  #       "is_flagged": false,
  #       "is_deleted": false,
  #       "root_post_id": 1,
  #       "parent_post_id": 1,
  #       "depth": 1,
  #       "wallable_id": 1,
  #       "wallable_type": "Promotion",
  #       "photo": {
  #         "url": "/images/photo.jpg",
  #         "thumb": {
  #           "url": "/images/thumb_photo.jpg"
  #         }
  #       },
  #       "postable": {...},
  #       "replies": {...}, // child posts
  #       "likes": {...},
  #       "user": {...},
  #       "created_at": "2014-03-13T14:29:58-04:00",
  #       "updated_at": "2014-03-13T14:29:58-04:00",
  #       "url": "http://api.hesapps.com/posts/1"
  #     }]
  #     "max_id": 20
  #   }
  def index
    psize = params[:page_size].nil? ? Post::PAGESIZE : params[:page_size]
    if params[:user_id].nil?
      if params[:location].nil?
        @posts =
        if params[:max_id].nil? && params[:since_id].nil?
          @wallable.posts.top.limit(psize)
        elsif params[:max_id]
          @wallable.posts.top.limit(psize).before(params[:max_id])
        else
          @wallable.posts.top.limit(psize).after(params[:since_id])
        end
      else
        @posts =
        if params[:max_id].nil? && params[:since_id].nil?
          @wallable.posts.locationed(params[:location]).top.limit(psize)
        elsif params[:max_id]
          @wallable.posts.locationed(params[:location]).top.limit(psize).before(params[:max_id])
        else
          @wallable.posts.locationed(params[:location]).top.limit(psize).after(params[:since_id])
        end
      end
      
      response = {
        :data => @posts,
        :meta => {
          :page_size => psize,
          :total_records => params[:location].nil? ? @wallable.posts.top.count : @wallable.posts.locationed(params[:location]).top.count
        }
      }

      if !@posts.empty?
        if @posts.last.id != (@wallable || @postable).posts.top.last.id
          response[:meta][:next] = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&max_id=#{@posts.last.id}&page=#{(params[:page].to_i || 1) + 1}"
        end

        if @posts.first.id != (@wallable || @postable).posts.top.first.id
          response[:meta][:prev] = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&since_id=#{@posts.first.id}&page=#{(params[:page].to_i || 1) - 1}"
        end
      end

      return HESResponder(response)

      # TODO: finish this up, when Drew starts on it.
      
      old = {
        :posts => @posts.to_a,
        :page => params[:page] || 1,
        :post_count => @wallable.posts.top.count,
        :reply_count => @wallable.posts.reply.count,
        :max_id => @posts.last.id,
        :next_page_url => "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&max_id=#{@posts.last.id}&page=#{(params[:page].to_i || 1) + 1}",
        :since_id => @posts.last.id,
        :prev_p => "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&since_id=#{@posts.first.id}&page=#{(params[:page].to_i || 1) - 1}"
      }




      @paged_posts = {
        :posts => @posts.to_a.each{|x| 
          # add_url(x, :is_collection => true)
        },
        :page => params[:page] || 1,
        :post_count => @wallable.posts.top.count,
        :reply_count => @wallable.posts.reply.count
      }

      unless @posts.empty?
        unless @posts.last.id == (@wallable || @postable).posts.first.id
          @paged_posts[:max_id] = @posts.last.id
          @paged_posts[:next_page_url] = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&max_id=#{@posts.last.id}&page=#{(params[:page].to_i || 1) + 1}"
        end

        unless @posts.first.id == (@wallable || @postable).posts.last.id
          @paged_posts[:since_id] = @posts.last.id
          @paged_posts[:prev_page_url] = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?").first}?#{params.map{|k, v| "#{k}=#{v}" unless ["max_id", "page", "action", "index", "controller"].include?(k.to_s)}.compact.join('&')}&since_id=#{@posts.first.id}&page=#{(params[:page].to_i || 1) - 1}"
        end
      end

      return HESResponder(@paged_posts)
    else
      @posts = @wallable.posts.top.where(:user_id => params[:user_id])
      return HESResponder(@posts)
    end
  end


  # Get posts ordering by popular weight
  #
  # @url [GET] /popular_posts
  # @authorize User
  # @param [String] wallable_type The type of model that owns the wall the post belongs to
  # @param [Integer] wallable_id The id of model that owns the wall the post belongs to
  # @return [Array<Post>] Array of Popular posts
  #
  # [URL] /popular_posts [GET]
  #  [200 OK] Successfully retrieved Posts Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }]

  def popular_posts
    # Popular weight determined by: (reply_weight + like_weight) * days_old_weight
    @popular_posts = @wallable.posts.top.sort_by {|post| ((post.replies.size * HesPosts.reply_weight) + post.likes.size * HesPosts.like_weight) * post.days_old_weight}.reverse
    @popular_posts = @popular_posts[0..19]

    return HESResponder(@popular_posts)
  end

  # Gets the list of flagged posts for a wallable instance
  #
  # @url [GET] /flagged_posts
  # @authorize Poster
  # @return [Array<Post>] Array of all posts
  #
  # [URL] /flagged_posts [GET]
  #  [200 OK] Successfully retrieved Posts Array object
  #   # Example response
  #   [{
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }]
  def flagged_posts
    @flagged_posts = Post.where(:is_flagged => true)

    #respond_to do |format|
    #  format.json { render :json => @flagged_posts, :include => [:wallable, :user] }
    #end
    return HESResponder(@flagged_posts)
  end

  # Gets a single post for a wallable
  #
  # @url [GET] /posts/1
  # @authorize User
  # @param [Integer] id The id of the post
  # @return [Post] Post that matches the id
  #
  # [URL] /posts/:id [GET]
  #  [200 OK] Successfully retrieved Post object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }
  def show
    @post = Post.find(params[:id]) rescue nil
    if !@post
      return HESResponder("Post", "NOT_FOUND")
    end
    return HESResponder(@post)
  end

  # Creates a single post for a wallable
  #
  # @url [POST] /promotions/1/posts/1
  # @authorize User
  # @param [String] wallable_type The type of model that owns the wall the post is being added to
  # @param [Integer] wallable_id The id of model that owns the wall the post is being added to
  # @param [String] content The message that the post contains
  # @param [String] photo The path to the image that will be created as a photo for the post
  # @param [Integer] parent_post_id The id of the parent post. If this is set then the post becomes a reply.
  # @param [Category] category The category of the post. Makes it easy to group posts.
  # @return [Post] Post that was just created
  #
  # [URL] /:wallable_type/:wallable_id/posts [POST]
  #  [201 CREATED] Successfully created Post object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }
  def create

    @post = (@wallable || @postable).posts.build
    @post.user_id = @current_user.id
    @post.update_attributes(params[:post])
    if !@post.valid?
      return HESResponder(@post.errors.full_messages, "ERROR")
    end
    @post.reload
    $redis.publish('newPostCreated', @post.to_json)
    return HESResponder(@post)
  end

  # Updates a single post for a wallable
  #
  # @url [PUT] /posts/1
  # @authorize User Can be flagged only by a user
  # @authorize Poster Can Flag and unflag
  # @param [Integer] id The id of the post
  # @param [Boolean] is_flagged Whether or not the post is flagged
  # @return [Post] Post that was just updated
  #
  # [URL] /posts/:id [PUT]
  #  [202 ACCEPTED] Successfully updated Post object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }
  def update
    @post = Post.find(params[:id]) rescue nil
    return HESResponder("Post", "NOT_FOUND") if !@post
    if @post.user_id != @current_user.id
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

  # Deletes a single post from a wallable
  #
  # @url [DELETE] /posts/1
  # @authorize User Can delete their own post
  # @authorize Poster
  # @param [Integer] id The id of the post
  # @return [Post] Post that was just deleted
  #
  # [URL] /posts/:id [DELETE]
  #  [200 OK] Successfully destroyed Post object
  #   # Example response
  #   {
  #     "id": 1,
  #     "content": "Love posting on this wall!!!!",
  #     "user_id": 1,
  #     "postable_id": 1,
  #     "postable_type": "Recipe",
  #     "category": "Nutrition",
  #     "is_flagged": false,
  #     "is_deleted": false,
  #     "root_post_id": 1,
  #     "parent_post_id": 1,
  #     "depth": 1,
  #     "wallable_id": 1,
  #     "wallable_type": "Promotion",
  #     "photo": {
  #       "url": "/images/photo.jpg",
  #       "thumb": {
  #         "url": "/images/thumb_photo.jpg"
  #       }
  #     },
  #     "postable": {...},
  #     "replies": {...}, // child posts
  #     "likes": {...},
  #     "user": {...},
  #     "created_at": "2014-03-13T14:29:58-04:00",
  #     "updated_at": "2014-03-13T14:29:58-04:00",
  #     "url": "http://api.hesapps.com/posts/1"
  #   }
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    return HESResponder(@post)
  end
end
