class GiftsController < ApplicationController
  authorize :all, :reorder, :master
  authorize :index, :show, :user

  before_filter :set_sandbox

  def set_sandbox
    @SB = use_sandbox? ? @promotion.gifts : Gift
  end
  private :set_sandbox
  
  def index
    return HESResponder(@SB.all)
  end

  def show
    gift = @SB.find(params[:id]) rescue nil
    return HESResponder("Gift", "NOT_FOUND") if !gift
    return HESResponder(gift)
  end

  def create
    gift = nil
    Gift.transaction do
      gift = @SB.create(params[:gift])
    end
    return HESResponder(gift.errors.full_messages, "ERROR") if !gift.valid?
    return HESResponder(gift)
  end

  def update
    gift = @SB.find(params[:id]) rescue nil
    return HESResponder("Gift", "NOT_FOUND") if !gift
    Gift.transaction do
      gift.update_attributes(params[:gift])
    end
    return HESResponder(gift.errors.full_messages, "ERROR") if !gift.valid?
    return HESResponder(gift)
  end

  def destroy
    gift = @SB.find(params[:id])
    Gift.transaction do
      gift.destroy
    end
    return HESResponder(gift)
  end

  def reorder
    return HESResponder("Must provide sequence.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array)
    gifts = @SB.all
    gift_ids = gifts.collect{|gift|gift.id}
    return HESResponder("Gift ids are mismatched.", "ERROR") if (gift_ids & params[:sequence]) != gift_ids
    sequence = 0
    params[:sequence].each{ |gift_id|
      gift = Gift.find(gift_id)
      gift.update_attributes(:sequence => sequence)
      sequence += 1
    }
    Gift.uncached do
      gifts = @SB.all
    end
    return HESResponder(gifts)
  end
end