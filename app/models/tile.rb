class Tile < ApplicationModel
  attr_accessible :title, :description, :image, :default, :default_seq, :behavior_id
  
  belongs_to :activity
end