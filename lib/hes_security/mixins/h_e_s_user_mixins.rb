module HESUserMixins
  def self.included(base)
    # make some nice methods for user? public? public_or_above?
    [:public,User::Role.keys].flatten.each do |k|
      define_method("#{k}?") {self.role==(User::Role[k]||:public)}
      define_method("#{k}_or_above?") {self.role_include?(k)}
    end

    def role_include?(required)
      HESControllerMixins.ri?(required,self.role||:public)
    end

    # may i go to PromotionsController#update action?  easy way of seeing if a user can do something.  
    # quite useful in the full Ruby on Rails stack.  limited use in an API.
    def may?(controller_constant,action_name,params={})
      HESControllerMixins.authorize_action(controller_constant,action_name,self,self.promotion,params)
    end
    
    # inverse of may?
    def maynot?(controller_constant,action_name,params={})
      !may?(controller_constant,action_name,params)
    end
  end
end
