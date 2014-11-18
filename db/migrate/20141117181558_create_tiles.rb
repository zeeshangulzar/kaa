class CreateTiles < ActiveRecord::Migration
  def change
  	create_table :tiles do |t|
  	  t.references :activities
  	  t.string    	:title,						  :limit => 50
  	  t.string    	:description,       :limit => 250
  	  t.string    	:image
  	  t.boolean   	:default,					  :default => false
  	  t.integer   	:default_seq

  	  t.timestamps
    end
  end
end