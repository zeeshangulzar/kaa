module HesRateable
  # Methods added to user model for sharing content
  module RateableUserMethods
    # Adds association to shares and methods for sharing content
    def can_rate
      self.send(:has_many, :ratings, :dependent => :destroy)
      self.send(:include, RateableUserInstanceMethods)
    end

    # Instance methods for sharing content
    module RateableUserInstanceMethods
      # Creates a new share
      #
      # @param [ActiveRecord::Base] rateable instance that is being rated
      # @return [Rating] rating that was just created
      def rate(rateable, score)
        _rating = ratings.build
        _rating.rateable = rateable
        _rating.score = score
        _rating.save
        _rating
      end

    end
  end
end
