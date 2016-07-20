class RoutesController < ApplicationController
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :master

  before_filter :set_sandbox, :only => [:index, :create]
  def set_sandbox
    if use_sandbox?
      if params[:map_id]
        @SB = @promotion.maps.active.find(params[:map_id]).routes rescue nil
        return HESResponder("Map", "NOT_FOUND") if @SB.nil?
      else
        return HESResponder("Map required.", "ERROR")
      end
    else
      @SB = Route
    end
  end
  private :set_sandbox

  def index
    # TODO: need a nice CONSISTENT way to handle statuses across models
    # using params, taking into account role, and don't forget caching!
    scope = 'active'
    if @current_user.master?
      scope = 'all'
    end
    return HESResponder(@SB.send(scope))
  end
  def show
    @SB = Route.active
    if @current_user.master?
      @SB = Route
    end
    route = @SB.find(params[:id]) rescue nil
    return HESResponder("Route", "NOT_FOUND") if route.nil?
    return HESResponder("Route", "NOT_FOUND") if !@current_user.master? && !@promotion.maps.include?(route.map)
    return HESResponder(route)
  end
  def create
    route = nil
    Route.transaction do
      route = @SB.build(params[:route]) rescue nil
      return HESResponder(route.errors.full_messages, "ERROR") if !route.valid?
      route.save!
    end
    return HESResponder(route)
  end
  def update
    route = Route.find(params[:id]) rescue nil
    return HESResponder("Route", "NOT_FOUND") if route.nil?
    Route.transaction do
      route.update_attributes(params[:route])
    end
    return HESResponder(route)
  end
  def destroy
    route = Route.find(params[:id]) rescue nil
    return HESResponder("Route", "NOT_FOUND") if route.nil?
    Route.transaction do
      route.destroy
    end
    return HESResponder(route)
  end
end