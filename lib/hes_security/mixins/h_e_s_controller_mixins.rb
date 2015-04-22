# Authorization module allows you to specify rules for access based on role
module HESControllerMixins
  module ClassMethods
    # Authorize appends to the default rules (if any)
    # @param actions list of actions as symbols
    # @param rule rule for access can be either a symbol or a +lambda+ that evaluates to +true|false+
    # @example
    #    # Allow any action to be accessed by anyone
    #    authorize :all, :public
    #    # Require a user with a minimum role of User to see the show action
    #    authorize :show, :user
    #    # Authorize several actions for master admin access
    #    authorize :edit, :create, :destroy, :master
    #    # Define a complex rule to only allow the owner of a resource to delete
    #    # Rules that use lambda should always return true or false
    #    # At runtime, lambdas are passed the user, promotion and request parameters as input
    #    authorize :destroy, lambda { |user, promotion, parameters| !user.resources.find_by_id(parameters[:id]).nil? }
    def authorize(*args)
      @@authorized_actions ||= {}
      @@authorized_actions[self.to_s] ||= []
      rule = args.pop
      args.each do |a|
        @@authorized_actions[self.to_s] << { :rule => rule, :action => a }
      end
    end
    
    # Provides internal access to the defined rules
    # @return [Hash]
    def authorizations
      @@authorized_actions ||= {}
      @@authorized_actions
    end
  end




  # Defines the hiearchy of roles and determines whether the specified role is allowed
  # @example
  #    # Defined roles (in hierarchy)
  #    :master # Master admin, highest level of access only granted for HES
  #      :reseller # Strategic partnerships allow access to multiple organizations
  #        :coordinator # Access for the organizational level
  #          :user # Standard user level access
  def self.ri?(rule,role)
    role = role.to_s.parameterize.underscore.to_sym
    if rule == :master
      [ :master ].include?(role)
    elsif rule == :poster
      [ :poster, :master ].include?(role)
    elsif rule == :reseller
      [ :reseller, :master ].include?(role)
    elsif rule == :coordinator
      [ :coordinator, :reseller, :master ].include?(role)
    elsif rule == :sub_promotion_coordinator
      [ :sub_promotion_coordinator, :coordinator, :reseller, :master ].include?(role)
    elsif rule == :regional_coordinator
      [ :regional_coordinator, :sub_promotion_coordinator, :coordinator, :reseller, :master ].include?(role)
    elsif rule == :location_coordinator
      [ :location_coordinator, :regional_coordinator, :sub_promotion_coordinator, :coordinator, :reseller, :master ].include?(role)
    elsif rule == :user
      [ :user, :poster, :location_coordinator, :regional_coordinator, :sub_promotion_coordinator, :coordinator, :reseller, :master ].include?(role)
    elsif rule == :public
      [ :public, :user, :poster, :location_coordinator, :regional_coordinator, :sub_promotion_coordinator, :coordinator, :reseller, :master ].include?(role)
    else
      false
    end
  end


  # Determine whether the current request is allowed based on the authorizations rules
  # @return (Boolean) if not authorized action is halted and returns 401 Unauthorized
  def self.authorize_action(controller,action_name,user,promotion,params)
    # no need to authorize master -- he can do anything
    return true if user && user.master?
            
    # gets all of the current controllers ancestestry (including self in hierarchical order)
    ancestors = controller.ancestors.grep(Class)
    at_least_one_rule_processed = false
    # Loop through the ancestry to determine the rules that may apply to this action
    ancestors.each do |a|
      unless controller.authorizations[a.to_s].nil?
        # Get just the rules that apply to this action (or :all)
        authorizations = controller.authorizations[a.to_s].select { |x| x[:action] == action_name.to_sym || x[:action] == :all }
        # Loop through the applicable rules
        authorizations.each do |auth|
          # Get the current rule
          rule = auth[:rule]
          action = auth[:action]

          # If it's public, we're good to go
          if rule == :public
            return true
          # process the rules to authorize the request
          else
            # No reason to continue if authentication failed since we know it's a requirement
            return false unless user

            # now see if any rules match the authenticated user
            # We'll consider the action valid if it matches the specified action or :all is provided
            if rule.is_a?(Proc)
              at_least_one_rule_processed = true
              return true if rule.call(user,promotion,params)
            elsif ri?(rule,user.role)
              at_least_one_rule_processed = true
              return true
            end
          end
        end
      end
      
      # Stop processing the loop if we've reached beyond the ApplicationController
      if a == ApplicationController || at_least_one_rule_processed
        break # exit the loop
      end
    end

    return false 
  end
end
