class GiftsController < ApplicationController
  authorize :all, :reorder, :master
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
    gift = nil
    Gift.transaction do
      gift = Gift.create(params[:gift])
    end
    return HESResponder(gift.errors.full_messages, "ERROR") if !gift.valid?
    return HESResponder(gift)
  end

  def update
    gift = Gift.find(params[:id]) rescue nil
    return HESResponder("Gift", "NOT_FOUND") if !gift
    Gift.transaction do
      gift.update_attributes(params[:gift])
    end
    return HESResponder(gift.errors.full_messages, "ERROR") if !gift.valid?
    return HESResponder(gift)
  end

  def destroy
    gift = Gift.find(params[:id])
    Gift.transaction do
      gift.destroy
    end
    return HESResponder(gift)
  end

  def reorder
    return HESResponder("Must provide sequence.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array)
    gifts = @promotion.gifts

    gift_ids = gifts.collect{|gift|gift.id}
    return HESResponder("Gift ids are mismatched.", "ERROR") if (gift_ids & params[:sequence]) != gift_ids
    sequence = 0
    params[:sequence].each{ |gift_id|
      gift = Gift.find(gift_id)
      gift.update_attributes(:sequence => sequence)
      sequence += 1
    }
    Gift.uncached do
      gifts = @promotion.gifts
    end
    return HESResponder(gifts)
  end
end