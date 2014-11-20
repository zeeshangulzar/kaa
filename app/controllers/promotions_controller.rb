class PromotionsController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :public

  def index
    return HESResponder(Promotion.find(:all,:include=>:profile))
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
      return HESResponder("Promotion doesn't exist.", 'NOT_FOUND')
    end
    return HESResponder(promotion)
  end

  def create
    # todo
  end
  
  def update
    # todo
  end
  
  def destroy
    # todo
  end

end
