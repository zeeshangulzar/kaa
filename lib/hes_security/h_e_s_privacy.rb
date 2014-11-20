module HESPrivacy
  extend ActiveSupport::Concern

  WhitelistAttributes = [:id]
  NoPathToUser = [:none]

  def self.included(base)
    add_to(base)
  end
  
  def self.extended(base)
    add_to(base)
  end
  
  def self.add_to(base)
    base.class_eval do
      define_method("attributes".to_sym){
        unless HESSecurityMiddleware.disabled?
          requester = HESSecurityMiddleware.current_user
          list = self.class.reduce_keys(requester,self)
        else
          list = *self.class.column_names
        end
        Hash[list.map{ |name| [name, self.read_attribute(name)]}]
      }
    end
  end
 
  module ClassMethods
    def init
      @@hes_privacy_config ||= {}
      @@hes_privacy_config[self] ||= {:path_to_user=>:user,:rules=>[]}
    end

    def get_privacy_hash
      init
      @@hes_privacy_config[self]
    end

    def inspect_privacy
      init
      @@hes_privacy_config.collect{|k,v|{k.to_s=>v}}.inspect
    end

    def attr_privacy(*args)
      init
      # examine *args for a list of symbols
      #        last symbol will be the privacy test:
      #           a role such as :user
      #           a pointer to a helper function such as :me
      #           a lambda so the developer can hand-craft whatever is necessary
      test = args.pop
      @@hes_privacy_config[self][:rules] << {:attrs=>args,:test=>test}
    end

    # parents of the User model have no path to user (e.g. Entry belongs_to User but Reseller has no relationship to User) 
    def attr_privacy_no_path_to_user
      init
      @@hes_privacy_config[self][:path_to_user] = NoPathToUser 
    end

    # this should only have to be specified if the model not a child of User (i.e. TeamMembership -> Team -> User)
    def attr_privacy_path_to_user(*path)
      init
      # *path will be:
      #   a single symbol such as :contactable (i.e. this model is a child of User, such as Contact)
      #   an array such as :entry, :user (i.e. this model is grandchild of user, such as Entry)
      #   a lambda (i.e. this model has no association to user, and the lamba will return the user)
      @@hes_privacy_config[self][:path_to_user] = path 
    end
    
    :private
    def get_user_from_target(target)
      return target if target.is_a?(User)
      
      path_to_user = @@hes_privacy_config[self][:path_to_user]
      return User.find(:first,:conditions=>{:role=>User::Role[:master]}) if path_to_user == NoPathToUser

      tgt = target
      ptu = path_to_user.is_a?(Array) ? path_to_user : [path_to_user]
      ptu.each do |path_item|
        begin
          tgt = tgt.send(path_item)       
        rescue Exception => ex
          if ex.is_a?(NoMethodError)      
            raise "#{tgt.class} does not have a method named #{path_item}.  Perhaps you need to specify attr_privacy_path_to_user or attr_privacy_no_path_to_user"
          else
            raise ex
          end
        end
      end
      tgt
    end

    def reduce_keys(requester,target)
      init
      remaining_keys = WhitelistAttributes.dup
      if target || (requester && requester.master?)
        rules = @@hes_privacy_config[self][:rules]
        rules.each do |rule_hash|
          ok = false
          # pay close attention to the order of the first 3 conditions below!
          if rule_hash[:test] == :public
            ok = true
          end
          if !requester.nil?
            target_user = get_user_from_target(target)
            if rule_hash[:test] == :any_user
              ok = !requester.nil?
            elsif rule_hash[:test] == :master
              ok = requester.master?
            elsif requester.master?
              ok = true
            elsif rule_hash[:test] == :me
              ok = requester == target_user
            elsif rule_hash[:test] == :connections
              #user now has a method named ids_of_connections to the user model that executes a SQL query that returns the type and id of every friend, team member, etc.
              if target_user
                if target_user.respond_to?(:ids_of_connections)
                  ok = target_user.ids_of_connections.include?(requester.id)
                else
                  Rails.logger.warn "HESPrivacy warning: :connections was specified but #{target_user.class.to_s} does not have a method named ids_of_connections"
                end
              end
            elsif rule_hash[:test] == :public_comment
              #user now has a method named has_made_self_known_to_public? to the user model that executes a SQL query that returns whether the user has likes or posts
              if target_user
                if target_user.respond_to?(:has_made_self_known_to_public?)
                  ok = (requester.poster? || target_user.promotion_id == requester.promotion_id) && target_user.has_made_self_known_to_public?
                else
                  Rails.logger.warn "HESPrivacy warning: :public_comment was specified but #{target_user.class.to_s} does not have a method named has_made_self_known_to_public?"
                end
              end
            end
          end
          remaining_keys += rule_hash[:attrs] if ok
        end
      end
      remaining_keys.collect{|k|k.to_s}
    end
  end
end

ActiveRecord::Base.send(:include, HESPrivacy)

if defined?(Rails::Console) && !HESSecurityMiddleware.disabled?
  puts "Because this is a console, you are an unauthenticated user."
  puts "You must call HESSecurityMiddleware.disable!"
  puts "If you want HESSecurity disabled automatically, set the environment variable HES_SECURITY_DISABLED=true (e.g. HES_SECURITY_DISABLED=true rails runner)"
end
