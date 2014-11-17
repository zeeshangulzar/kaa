class UserTilesController < ApplicationController
  authorize :index, :show, :destroy, :user

  def index
    @tiles = []
    @user_tiles = UserTile.find_all_by_user_id(params[:user_id]).order_by(:sequence)
    @user_tiles.each do |t|
      @tiles << Tile.find(t.tile_id)
    end
    respond_with @tiles
  end

  def show
    respond_with UserTile.find(params[:id])
  end

  def create
    respond_with UserTile.create(params[:user_tile])
  end

  def destroy
  	respond_with UserTile.destroy(params[:id])
  end
end
