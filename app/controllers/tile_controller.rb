class TilesController < ApplicationController
  authorize :index, :show, :user
  authorize :destroy, :master

  def index
    return HESResponder(Tile.all)
  end

  def show
    return HESResponder(Tile.find(params[:id]))
  end

  def create
    return HESResponder(Tile.create(params[:tile]))
  end

  def destroy
  	return HESResponder(Tile.destroy(params[:id]))
  end
end
