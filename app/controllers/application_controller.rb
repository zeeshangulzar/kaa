class ApplicationController < ActionController::Base
  protect_from_forgery

  respond_to :json

  before_filter :set_user_and_promotion
  before_filter :set_default_format_json

  # Sets the default format to json unless a different format is request.
  def set_default_format_json
    if params[:format] && params[:format] != 'json'
      head :bad_request
    else
      request.format = 'json' unless params[:format]
    end
  end

  def set_user_and_promotion
    # first set it to me and my promotion
    @user = HESSecurityMiddleware.current_user
    if @user
      @promotion = @user.promotion

      if params[:promotion_id]
        can_change_promotion = false
        other_promotion = Promotion.find(params[:promotion_id])
        if @user.master? || @user.poster?
          can_change_promotion = true
        elsif @user.reseller? && other_promotion.organization.reseller_id == @user.promotion.organization.reseller_id
          can_change_promotion = true
        elsif @user.coordinator? && other_promotion.organization_id == @user.promotion.organization_id
          can_change_promotion = true
        end
        if can_change_promotion
          @promotion = other_promotion 
        end
      end
    else
      # what if promotion does not exist or is not active????
      info = DomainConfig.parse(request.host)
      if info[:subdomain]
        promotion = Promotion.find_by_subdomain(info[:subdomain])
        if promotion && promotion.is_active
          @promotion = promotion
        end
      end
    end
  end

end
