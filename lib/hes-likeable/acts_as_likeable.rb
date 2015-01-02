module HesLikeable
  # Acts as likeable module
  module ActsAsLikeable
    mattr_accessor :non_active_record_likeables
    self.non_active_record_likeables = []

    mattr_accessor :like_labels
    self.like_labels = []

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
      def acts_as_likeable(options = {})

        unless ActiveRecord::Base.connection.tables.include?(Like.table_name)
          puts "Likes table must be created before using hes-likeable. Please run rails generate hes:likeable then rake db:migrate it create table."
        else
          
          self.send(:cattr_accessor, "like_label")
          self.send(:cattr_accessor, "unlike_label")

          self.like_label = like_label = options.delete(:label) || 'Like'
          self.unlike_label = unlike_label = options.delete(:opposite_label) || "Un#{self.like_label.downcase}"

          if self <= ActiveRecord::Base
            self.send(:has_many, :likes, {:as => :likeable, :include => :user, :dependent => :destroy}.merge(options || {}))
            self.send(:alias_method, self.like_label.tableize.to_sym, :likes) if self.like_label != 'Like'
          else

            self.send(:define_method, :likes) do
              Like.where(:likeable_type => self.class.to_s, :likeable_id => self.id).includes(:user)
            end

            self.send(:alias_method, self.like_label.tableize.to_sym, :likes) if self.like_label != 'Like'

            self.send(:define_method, :destroy) do
              Like.where(:likeable_type => self.class.to_s, :likeable_id => self.id).destroy_all
              super
            end

            HesLikeable::ActsAsLikeable.non_active_record_likeables << self
          end

          send :include, InstanceMethods

          label_verb = self.like_label.last == 'e' ? "#{self.like_label}d" : "#{self.like_label}ed"
          opposite_label_verb = self.unlike_label.last == 'e' ? "#{self.unlike_label}d" : "#{self.unlike_label}ed"

          self.send(:alias_method, "#{label_verb.underscore.downcase}_by", :liked_by) unless self.like_label == 'Like'
          self.send(:alias_method, "#{opposite_label_verb.underscore.downcase}_by", :unliked_by) unless self.unlike_label == 'Unlike'

          model_name = self.to_s
          HesLikeable::ActsAsLikeable.like_labels << [like_label, unlike_label, label_verb, model_name]
          if defined?(User)
            User.class_eval do
              alias_method like_label.underscore.downcase, :like
              alias_method unlike_label, :unlike
              define_method("#{label_verb.underscore.downcase}_#{model_name.downcase.pluralize}".to_sym) do
                self.send(like_label.tableize.to_sym).typed(model_name).collect{|l| l.likeable}
              end
            end
          end
        end
      end
    end

    # Instance methods for a likeable object
    module InstanceMethods

      # Creates a new like
      #
      # @param [User] user that the like belongs to
      # @return [Like] like that was just created
      def liked_by(user)
        _like = self.send(self.class.like_label.tableize.to_sym).build
        _like.user = user
        _like.save
        _like
      end

      # Destroys the like tied to this user on this likeable model
      #
      # @param [User] user that the like belongs to
      # @return [Boolean] whether or not like was successfully destroyed
      def unliked_by(user)
        self.send(self.class.like_label.tableize.to_sym).find_by_user_id(user.id).destroy rescue false
      end
    end
  end
end
