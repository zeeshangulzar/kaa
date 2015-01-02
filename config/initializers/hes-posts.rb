require 'hes-posts/engine'

# HES Posts module, default configurations also set here
module HesPosts

  mattr_accessor :reply_weight
  mattr_accessor :like_weight
  mattr_accessor :days_old_weight

  # The weight of replies and likes based on popular_posts
  self.reply_weight = 2.5
  self.like_weight = 1

  # The weight of how old the post is based on popular_posts
  self.days_old_weight = {
    7 => 0.9,
    14 => 0.7,
    30 => 0.5
  }




  # Not used
  mattr_accessor :uses_notifications

  mattr_accessor :post_liked_notification_title
  mattr_accessor :post_liked_notification_message

  mattr_accessor :post_replied_notification_title
  mattr_accessor :post_replied_notification_message

  mattr_accessor :expert_post_liked_notification_message
  mattr_accessor :expert_post_replied_notification_message

  self.uses_notifications = true

  # Title of a notification that is sent when a post is liked
  self.post_liked_notification_title = lambda {|post, like| "Your post was liked!"}

  # Content of a notification that is sent when a post is liked
  self.post_liked_notification_message = lambda {|post, like| "#{like.user.name} liked your <a href='/posts/#{post.id}'>post</a>!"}


  # Title of a notification that is sent when a post is replied to
  self.post_replied_notification_title = lambda {|post, reply| "Your post was replied to!"}

  # Content of a notification that is sent when a post is replied to
  self.post_replied_notification_message = lambda {|post, reply| "#{reply.user.name} replied to your <a href='/posts/#{post.id}?reply=#{reply.id}'>post</a>!"}


  # Title of a notification that is sent when an expert post is liked
  self.expert_post_liked_notification_message = lambda {|post, like| "#{like.user.name} liked your <a href='/wall_expert_posts/#{post.id}'>post</a>!"}

  # Content of a notification that is sent when an expert post is replied
  self.expert_post_replied_notification_message = lambda {|post, reply| "#{reply.user.name} replied to your <a href='/wall_expert_posts/#{post.id}?reply=#{reply.id}'>post</a>!"}
end
