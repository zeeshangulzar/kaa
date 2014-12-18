module HesPosts

  # Module that makes an ActiveRecord model postable on to a wallable object
  module IsPostable
  	
    # Class method used to show a model wants to be postable. Adds has many association to posts as a postable object.
    def is_postable
      self.send(:has_many, :posts, :as => :postable)
    end
  end
end
