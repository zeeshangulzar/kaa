class UserTile < ActiveRecord::Base
  attr_accessible :tile_id, :sequence, :user_id
  
  belongs_to :user
  belongs_to :tile
end
