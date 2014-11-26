class PromotionsController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :master

  authorize :show, :public
  authorize :index, :poster
  authorize :create, :update, :destroy, :master

  def index
    promotions = params[:organization_id] ? Organization.find(params[:organization_id]).promotions : params[:reseller_id] ? Reseller.find(params[:reseller_id]).promotions : Promotion.all
    return HESResponder(promotions)
  end

  # Get a promotion
  #
  # @url [GET] /promotions/1
  # @param [Integer] id The id of the promotion
  # @return [Promotion] Promotion that matches the id
  #
  # [URL] /promotions/:id [GET]
  #  [200 OK] Successfully retrieved Promotion
  def show
    promotion = Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion doesn't exist.", "NOT_FOUND")
    end
    return HESResponder(promotion)
  end

  def create
    promotion = Promotion.create(params[:promotion])
    if !promotion.valid?
      return HESResponder(promotion.errors.full_messages, "ERROR")
    end
    return HESResponder(promotion)
  end
  
  def update
    promotion = Promotion.find(params[:id])
    if !promotion
      return HESResponder("Promotion doesn't exist.", "NOT_FOUND")
    else
      if !promotion.update_attributes(params[:promotion])
        return HESResponder(promotion.errors.full_messages, "ERROR")
      else
        return HESResponder(promotion)
      end
    end
  end
  
  def destroy
    promotion = Promotion.find(params[:id]) rescue nil
    if !promotion
      return HESResponder("Promotion doesn't exist.", "NOT_FOUND")
    elsif promotion.destroy
      return HESResponder(promotion)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end
