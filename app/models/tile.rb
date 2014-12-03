class Tile < ApplicationModel
  attr_accessible :title, :description, :image, :default, :default_seq, :activity_id
  
  belongs_to :activity
end