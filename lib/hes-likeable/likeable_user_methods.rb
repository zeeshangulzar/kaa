module HesLikeable
  # Methods added to user model for liking content
  module LikeableUserMethods
    # Adds association to likes and methods for liking content
    def can_like
      self.send(:has_many, :likes, :dependent => :destroy)
      self.send(:include, LikeableUserInstanceMethods)
      HesLikeable::ActsAsLikeable.like_labels.each do |like_label, unlike_label, label_verb, model_name|
        self.class_eval do
          alias_method like_label.underscore.downcase, :like if like_label.to_s != "Like"
          alias_method unlike_label, :unlike if unlike_label.to_s != "unlike"
          define_method("#{label_verb.underscore.downcase}_#{model_name.downcase.pluralize}".to_sym) do
            self.send(like_label.tableize.to_sym).typed(model_name).collect{|l| l.likeable}
          end
        end
      end
    end

    # Instance methods for liking content
    module LikeableUserInstanceMethods
      # Creates a new like
      #
      # @param [ActiveRecord::Base] likeable instance that is being liked
      # @return [Like] like that was just created
      def like(likeable)
        _like = likes.build
        _like.likeable = likeable
        _like.save
        _like
      end

      # Destroys the like tied to this user on this likeable model
      #
      # @param [ActiveRecord::Base] likeable instance that is being un-liked
      # @return [Boolean] whether or not like was successfully destroyed
      def unlike(likeable)
        likes.find_by_likeable_id_and_likeable_type(likeable.id, likeable.class.to_s).destroy rescue false
      end
    end
  end
end
