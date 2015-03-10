module HesRateable
  # Acts as likeable module
  module ActsAsRateable
    mattr_accessor :non_active_record_rateables
    self.non_active_record_rateables = []

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
      def acts_as_rateable(options = {})

        unless ActiveRecord::Base.connection.tables.include?(Rating.table_name)
          puts "Ratings table must be created before using hes-rateable."
        else

          if self <= ActiveRecord::Base
            self.send(:has_many, :ratings, {:as => :rateable, :include => :user, :dependent => :destroy}.merge(options || {}))
            
            self.send(:define_method, :rating) do
              return Rating.average(:score, :conditions => {:rateable_type => self.class.to_s, :rateable_id => self.id}).to_f
            end

          else

            self.send(:define_method, :ratings) do
              Rating.where(:rateable_type => self.class.to_s, :rateable_id => self.id).includes(:user)
            end

            self.send(:define_method, :destroy) do
              Rating.where(:rateable_type => self.class.to_s, :rateable_id => self.id).destroy_all
              super
            end

            HesRateable::ActsAsRateable.non_active_record_rateables << self
          end

          send :include, InstanceMethods

          model_name = self.to_s

          if defined?(User)
            User.class_eval do
              define_method("rated_#{model_name.downcase.pluralize}".to_sym) do
                self.send(:rate).typed(model_name).collect{|s| s.rateable}
              end
            end
          end
        end
      end
    end

    # Instance methods for a likeable object
    module InstanceMethods

      # Creates a new rating
      #
      # @param [User] user that the like belongs to
      # @return [Rating] rating that was just created
      def rated_by(user, score)
        _rating = self.send(:ratings).build
        _rating.user = user
        _rating.value = score
        _rating.save
        _rating
      end

    end
  end
end
