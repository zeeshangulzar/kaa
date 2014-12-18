module HesPosts
  
	# Module to make an ActiveRecord model into a wall
  module HasWall

  	# Class method to make model into a wall. Adds has many association to posts as wallable object.
    def has_wall
      self.send(:has_many, :posts, :as => :wallable)
      self.send(:include, HasWallInstanceMethods)
    end

    # Instance methods added once a model becomes wallable
    module HasWallInstanceMethods

    	# Creates a post that is tied to the wallable instance.
    	# @param [User] user that is posting to wall
    	# @param [String] content of the post generate by user or app
    	# @param [Postable] postable model that is related to this post
    	# @return [Post] post that is now tied to wall
    	# @example
    	#  @promotion.add_post(@user, "Can't wait to exercise today!")
    	#  @promotion.add_post(@user, "This recipe looks awesome!", @recipe)
      def add_post(user, content, postable = nil)
        post = posts.build(:content => content)
        post.user = user
        post.postable = postable
        post.save
        post
      end
    end
  end
end
