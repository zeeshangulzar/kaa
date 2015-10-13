class PromotionsController < ApplicationController
  authorize :index, :create, :update, :destroy, :master

  authorize :show, :current, :top_location_stats, :verify_users_for_achievements, :authenticate, :public
  authorize :index, :poster
  authorize :create, :update, :destroy, :keywords, :master

  def index
    promotions = params[:organization_id] ? Organization.find(params[:organization_id]).promotions : params[:reseller_id] ? Reseller.find(params[:reseller_id]).promotions : Promotion.all
    return HESResponder(promotions)
  end


  def show
    promotion = (params[:id] == 'current') ? @promotion : Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    end
    return HESResponder(promotion)
  end

  def current
    if @current_user && @current_user.user?
      seconds_to_midnight = (@promotion.current_date + 1).to_time.to_i - @promotion.current_time.to_i # expire promotion cache at start of new day so frontend can use @promotion.current_date
      return HESCachedResponder(@promotion.cache_key, @promotion, {:cache_options=>{:expires_in => seconds_to_midnight}})
    end
    return HESResponder(@promotion)
  end

  def create
    promotion = nil
    Promotion.transaction do
      promotion = Promotion.create(params[:promotion])
      if !promotion || !promotion.valid?
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        if !params[:promotion][:flags].nil?
          params[:promotion][:flags].each{|f,v|
            if !promotion.flags[f.to_sym].nil?
              promotion.flags[f.to_sym] = v
            end
          }
          promotion.save!
        end
      end
    end
    return HESResponder(promotion)
  end
  
  def update
    promotion = Promotion.find(params[:id])
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    else
      Promotion.transaction do
        promotion.update_attributes(params[:promotion])
        if !params[:promotion][:flags].nil?
          params[:promotion][:flags].each{|f,v|
            if !promotion.flags[f.to_sym].nil?
              promotion.flags[f.to_sym] = v
            end
          }
          promotion.save!
        end
      end
      if !promotion.valid?
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        return HESResponder(promotion)
      end
    end
  end
  
  def destroy
    promotion = Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion", "NOT_FOUND")
    elsif promotion.destroy
      return HESResponder(promotion)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

  def top_location_stats
    users = ActiveRecord::Base.connection.select_all("SELECT COUNT(*) AS 'user_count', locations.name FROM users INNER JOIN locations ON users.top_level_location_id = locations.id WHERE users.promotion_id = #{@promotion.id} GROUP BY locations.name;")
    render :json => {:data => users} and return
  end

  def keywords
    return HESResponder(@promotion.keywords)
  end

  def authenticate
    if params[:password] == @promotion.pilot_password
      return HESResponder()
    else
      return HESResponder("Invalid pilot password.", "UNAUTHORIZED")
    end
  end

  def can_register
    return HESResponder() if @promotion.max_participants.nil? || @promotion.max_participants > @promotion.total_participants
    return HESResponder("Maximum participants reached.", "ERROR")
  end

end
