class CreateUserTiles < ActiveRecord::Migration
  def change
  	create_table :user_tiles do |t|
  	  t.references :users, :tiles
  	  t.integer    :sequence

  	  t.timestamps
    end
  end
end