module HesShareable
  # Methods added to user model for sharing content
  module ShareableUserMethods
    # Adds association to shares and methods for sharing content
    def can_share
      self.send(:has_many, :shares, :dependent => :destroy)
      self.send(:include, ShareableUserInstanceMethods)
    end

    # Instance methods for sharing content
    module ShareableUserInstanceMethods
      # Creates a new share
      #
      # @param [ActiveRecord::Base] shareable instance that is being shared
      # @return [Share] share that was just created
      def share(shareable, via)
        _share = shares.build
        _share.shareable = shareable
        _share.via = via
        _share.save
        _share
      end

    end
  end
end
