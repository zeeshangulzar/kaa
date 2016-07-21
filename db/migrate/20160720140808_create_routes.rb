class CreateRoutes < ActiveRecord::Migration
  def self.up
    create_table :routes do |t|
      t.references  :map
      t.string :name
      t.string :travel_type
      t.integer :status, :default => Route::STATUS[:inactive]
      t.text :points
      t.timestamps
    end
  end

  def self.down
    drop_table :routes
  end
end
