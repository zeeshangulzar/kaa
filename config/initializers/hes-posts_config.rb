# The weight of replies and likes based on popular_posts
# self.reply_weight = 2.5
# self.like_weight = 1

# The weight of how old the post is based on popular_posts
# self.days_old_weight = {
#   7 => 0.9,
#   14 => 0.7,
#   30 => 0.5
# }

# Uncomment to change the defaults

#HesPosts.uses_notifications = true

# Title of a notification that is sent when a post is liked
#HesPosts.post_liked_notification_title = lambda {|post, like| "Your post was liked!"}

# Content of a notification that is sent when a post is liked
#HesPosts.post_liked_notification_message = lambda {|post, like| "#{like.user.name} liked your <a href='/posts/#{post.id}'>post</a>!"}


# Title of a notification that is sent when a post is replied to
#HesPosts.post_replied_notification_title = lambda {|post, reply| "Your post was replied to!"}

# Content of a notification that is sent when a post is replied to
#HesPosts.post_replied_notification_message = lambda {|post, reply| "#{reply.user.name} replied to your <a href='/posts/#{post.id}?reply=#{reply.id}'>post</a>!"}


# Title of a notification that is sent when an expert post is liked
#HesPosts.expert_post_liked_notification_message = lambda {|post, like| "#{like.user.name} liked your <a href='/wall_expert_posts/#{post.id}'>post</a>!"}

# Content of a notification that is sent when an expert post is replied
#HesPosts.expert_post_replied_notification_message = lambda {|post, reply| "#{reply.user.name} replied to your <a href='/wall_expert_posts/#{post.id}?reply=#{reply.id}'>post</a>!"}