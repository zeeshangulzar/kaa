class TilesController < ApplicationController
  authorize :index, :show, :user
  authorize :destroy, :master

  def index
    respond_with Tile.all
  end

  def show
    respond_with Tile.find(params[:id])
  end

  def create
    respond_with Tile.create(params[:tile])
  end

  def destroy
  	respond_with Tile.destroy(params[:id])
  end
end
