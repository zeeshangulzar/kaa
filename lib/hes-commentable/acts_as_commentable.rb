module HesCommentable
  # Commentable module
  module ActsAsCommentable
    mattr_accessor :non_active_record_commentables
    self.non_active_record_commentables = []

    # When the module is included, it's extended with the class methods
    # @param [ActiveRecord] base to extend
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # ClassMethods module for adding methods for comments
    module ClassMethods

      # Defines an assocation where the model contains many comments
      #
      # @example
      #  class Recipe < ActiveRecord::Base
      #    acts_as_commentable
      #    ...
      def acts_as_commentable
        unless ActiveRecord::Base.connection.tables.include?(Comment.table_name)
          puts "Comments table must be created before using hes-commentable. Please run rails generate hes:commentable then rake db:migrate it create table."
        else

          if self <= ActiveRecord::Base
            self.send(:has_many, :comments, :as => :commentable, :include => :user, :conditions => {:is_deleted => false}, :dependent => :destroy)
          else
            self.send(:define_method, :comments) do
              Comment.where(:commentable_type => self.class.to_s, :commentable_id => self.id, :is_deleted => false).includes(:user)
            end

            self.send(:define_method, :destroy) do
              Comment.where(:commentable_type => self.class.to_s, :commentable_id => self.id).destroy_all
              super
            end

            HesCommentable::ActsAsCommentable.non_active_record_commentables << self
          end

          model_name = self.to_s
          User.class_eval do
            define_method("commented_on_#{model_name.downcase.pluralize}".to_sym) do
              comments.typed(model_name).collect{|c| c.commentable}
            end
          end
        end
      end
    end
  end
end
