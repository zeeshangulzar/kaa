class PromotionsController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :public

  def index
    respond_with Promotion.find(:all,:include=>:profile)
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
      render :json => {:errors => ["Promotion doesn't exist."]}, :status => 404 and return
    end
    render :json => promotion and return
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
