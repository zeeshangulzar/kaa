# Controller for handling wall expert posts feature
class WallExpertPostsController < ApplicationController

  respond_to :json
  authorize :all, :poster

  # Gets a list of all wall expert posts
  #
  # @url [GET] /wall_expert_posts
  # @authorize Poster
  # @return [Array<Post>] Array of all posts
  #
  # [URL] /wall_expert_posts [GET]
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
  def index
    @posts = @user.promotion.posts.order("created_at DESC")
    respond_with @posts
  end

  # Creates posts in all active promotions
  #
  # @url [POST] /wall_expert_posts/1
  # @authorize Poster
  # @param [String] wallable_type The type of model that owns the wall the post is being added to
  # @param [Integer] wallable_id The id of model that owns the wall the post is being added to
  # @param [String] content The message that the post contains
  # @param [String] photo The path to the image that will be created as a photo for the post
  # @param [Category] category The category of the post. Makes it easy to group posts.
  # @return [Post] Post that was just created
  #
  # [URL] /wall_expert_posts [POST]
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
    @post = @user.promotion.posts.build(params[:wall_expert_post])
    @post.user = @user
    @post.save

    Promotion.where(:is_active => true).where("`promotions`.id != #{@user.promotion.id}").each do |promotion|
      post = promotion.posts.build(params[:wall_expert_post])
      post.user = @user
      if post.postable == nil
        post.postable = @post
      end
      post.save
    end

    respond_with @post
  end

  # Gets a single wall expert post
  #
  # @url [GET] /wall_expert_posts/1
  # @authorize Poster
  # @param [Integer] id The id of the post
  # @return [Post] Post that matches the id
  #
  # [URL] /wall_expert_posts/:id [GET]
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
    @post = @user.promotion.posts.find(params[:id])
    respond_with @post
  end

  # Updates a single wall expert post
  #
  # @url [PUT] /wall_expert_posts/1
  # @authorize Poster
  # @param [Integer] id The id of the post
  # @param [String] content The message that the post contains
  # @param [String] photo The path to the image that will be created as a photo for the post
  # @param [Category] category The category of the post. Makes it easy to group posts.
  # @return [Post] Post that was just updated
  #
  # [URL] /wall_expert_posts/:id [PUT]
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
    @post = @user.promotion.posts.find(params[:id])

    @post.update_attributes(params[:wall_expert_post])

    @post.posts.each do |post|
      post.update_attributes(params[:wall_expert_post]) unless post.nil?
    end

    respond_with(@post)
  end

  # Deletes a single wall expert post
  #
  # @url [DELETE] /wall_expert_posts/1
  # @authorize Poster
  # @param [Integer] id The id of the post
  # @return [Post] Post that was just deleted
  #
  # [URL] /wall_expert_posts/:id [DELETE]
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
    @post = @user.promotion.posts.find(params[:id])

    @post.posts.each do |post|
      post.destroy unless post.nil?
    end

    @post.destroy

    respond_with @post
  end
end
