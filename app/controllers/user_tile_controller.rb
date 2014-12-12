class UserTilesController < ApplicationController
  authorize :index, :show, :destroy, :user

  def index
    @tiles = []
    @user_tiles = UserTile.find_all_by_user_id(@user.id).order_by(:sequence)
    @user_tiles.each do |t|
      @tiles << Tile.find(t.tile_id)
    end
    return HESResponder(@tiles)
  end

  def show
    return HESResponder(UserTile.find(params[:id]))
  end

  def create
    return HESResponder(UserTile.create(params[:user_tile]))
  end

  def destroy
  	return HESResponder(UserTile.destroy(params[:id]))
  end
end
