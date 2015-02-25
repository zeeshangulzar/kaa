module HesShareable
  # Acts as likeable module
  module ActsAsShareable
    mattr_accessor :non_active_record_shareables
    self.non_active_record_shareables = []

    # When the module is included, it's extended with the class methods
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # ClassMethods module for adding methods for likes
    module ClassMethods

      # Defines an assocation where the model contains many likes
      #
      # @example
      #  class Recipe < ActiveRecord::Base
      #    acts_as_likeable
      #    ...
      def acts_as_shareable(options = {})

        unless ActiveRecord::Base.connection.tables.include?(Share.table_name)
          puts "Shares table must be created before using hes-shareable."
        else

          if self <= ActiveRecord::Base
            self.send(:has_many, :shares, {:as => :shareable, :include => :user, :dependent => :destroy}.merge(options || {}))
          else

            self.send(:define_method, :shares) do
              Share.where(:shareable_type => self.class.to_s, :shareable_id => self.id).includes(:user)
            end

            self.send(:define_method, :destroy) do
              Share.where(:shareable_type => self.class.to_s, :shareable_id => self.id).destroy_all
              super
            end

            HesShareable::ActsAsShareable.non_active_record_shareables << self
          end

          send :include, InstanceMethods

          model_name = self.to_s

          if defined?(User)
            User.class_eval do
              define_method("shared_#{model_name.downcase.pluralize}".to_sym) do
                self.send(:share).typed(model_name).collect{|s| s.shareable}
              end
            end
          end
        end
      end
    end

    # Instance methods for a likeable object
    module InstanceMethods

      # Creates a new share
      #
      # @param [User] user that the like belongs to
      # @return [Share] share that was just created
      def shared_by(user, via)
        _share = self.send(:shares).build
        _share.user = user
        _share.via = via
        _share.save
        _share
      end

    end
  end
end
