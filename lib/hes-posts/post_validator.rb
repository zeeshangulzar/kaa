module HesPosts

  # Custom Post Validator to tackle harder to handle rules that need to be enforced
  class PostValidator < ActiveModel::Validator

    # Custom validation of post
    # @param [Post] post to be validated
    # @return [Post] that has been validated and has errors added in invalid
    def validate(post)
      post = validate_parent_root_id(post)
      post = validate_wallable(post) unless post.depth.zero? || post.parent_post.nil?
    end

    # Validates parent_post_id and root_post_id are correct for the depth level of the post.
    # @example
    #  <Post :depth => 0, :parent_post_id => nil, :root_post_id => nil>
    #  <Post :depth => 1, :parent_post_id => 1, :root_post_id => 1>
    #  <Post :depth => 2, :parent_post_id => 2, :root_post_id => 1>
    # @param [Post] post that is being validated
    # @return [Post] post with errors if parent_post_id and root_post_id are not correct for the depth of the post
    def validate_parent_root_id(post)
      if post.depth.zero?
        if post.parent_post_id || post.root_post_id
          post.errors[:base] = "Post with depth of 0 should not have parent post or root post id"
        end
      elsif post.depth >= 1
        if post.parent_post_id.nil? || post.root_post_id.nil?
          post.errors[:base] = "Post with depth greater than 0 must have a parent post and root post"
        elsif post.depth == 1
          if post.parent_post_id != post.root_post_id
            post.errors[:base] = "Post with depth of 1 should have parent post and root post id equal"
          end
        else
          if post.parent_post_id == post.root_post_id
            post.errors[:base] = "Post with depth greater than 1 should not have parent post and root post id equal"
          elsif post.parent_post.root_post_id != post.root_post_id
            post.errors[:base] = "Post and parent post must have the same root post"
          end
        end
      end
      post
    end

    # Validates that a nested post has the same wallable instance as it's parent
    # @param [Post] post that is being validated
    # @return [Post] post with errors if child and parent post don't have the same wallable instance
    def validate_wallable(post)
      if post.wallable_type != post.parent_post.wallable_type || post.wallable_id != post.parent_post.wallable_id
        post.errors[:base] = "Post and parent post must have the same wallable id and wallable type"
      end
    end
  end
end
