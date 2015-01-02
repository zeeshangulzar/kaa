module HesPosts

  # Module that makes User a poster
  module UserPostMethods
    def can_post
      self.send(:has_many, :posts, :dependent => :destroy)
      self.send(:include, UserPostInstanceMethods)
    end

    module UserPostInstanceMethods
      # Creates a post from a user
      # @param [string] content about the postable post that is be created
      # @param [Postable] postable instance that is being shared in post, optional
      # @param [Wallable] wallable instance where the post should be added, optional
      # @return [Post] post that was created if wallable parameter was passed in, post that was build but not saved otherwise
      # @example
      #  @user.post("This recipe looks great!")
      #  @user.post("This recipe looks great!", nil, @promotion)
      #  @user.post("This recipe looks great!", @recipe).to(@promotion)
      # @note Post won't save if wallable is not passed in but will still be built. Use chain method post.to(@wallable) to save to a wall.
      def post(content, postable = nil, wallable = nil)
        post = self.posts.build(:content => content)
        post.wallable = wallable
        post.postable = postable
        post.save unless wallable.nil?
        post
      end
    end
  end

end
