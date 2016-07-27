class CreateDestinations < ActiveRecord::Migration
  def self.up
    create_table :destinations do |t|
      t.references  :map
      t.string :name
      t.string :icon1
      t.string :icon2
      t.text :content
      t.text :blurb
      t.text :question
      t.text :answers
      t.string :correct_answer
      t.string :status, :default => Route::STATUS[:active]
      t.integer :sequence
      t.timestamps
    end
  end

  def self.down
    drop_table :destinations
  end
end
