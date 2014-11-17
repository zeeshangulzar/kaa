class CreateUserTiles < ActiveRecord::Migration
  def change
  	create_table :user_tiles do |t|
  	  t.integer		:tile_id
  	  t.integer		:user_id
  	  t.integer   	:sequence

  	  t.timestamps
  end
end
