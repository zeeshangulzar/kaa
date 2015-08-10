class GiftsController < ApplicationController
  authorize :all, :master
  authorize :index, :show, :user
  
  def index
    gifts = !@promotion.nil? ? @promotion.gifts : Gift.all
    return HESResponder(gifts)
  end

  def show
    gift = Gift.find(params[:id]) rescue nil
    return HESResponder("Gift", "NOT_FOUND") if !gift
    return HESResponder(gift)
  end

  def create
    Gift.transaction do
      gift = Gift.create(params[:gift])
    end
    return HESResponder(gift)
  end

  def update
    gift = Gift.find(params[:id]) rescue nil
    return HESResponder("Gift", "NOT_FOUND") if !gift
    Gift.transaction do
      gift.update_attributes(params[:gift])
    end
    return HESResponder(gift.errors.full_messages) if !gift.valid?
    return HESResponder(gift)
  end

  def destroy
    gift = Gift.find(params[:id])
    Gift.transaction do
      gift.destroy
    end
    return HESResponder(gift)
  end
end