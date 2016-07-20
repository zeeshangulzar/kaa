class MapsController < ApplicationController
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :master
  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.maps : Map
  end
  private :set_sandbox
  def index
    return HESResponder(@SB.all)
  end
  def show
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    return HESResponder(map)
  end
  def create
    map = nil
    Map.transaction do
      map = @SB.new(params[:map]) rescue nil
      return HESResponder(map.errors.full_messages, "ERROR") if !map.valid?
      map.save!
    end
    return HESResponder(map)
  end
  def update
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    if !params[:settings].nil?
      params[:map] = scrub(params[:map].merge(params.delete(:settings)), Map)
    end
    Map.transaction do
      map.update_attributes(params[:map])
    end
    return HESResponder(map)
  end
  def destroy
    map = @SB.find(params[:id]) rescue nil
    return HESResponder("Map", "NOT_FOUND") if map.nil?
    Map.transaction do
      map.destroy
    end
    return HESResponder(map)
  end
end