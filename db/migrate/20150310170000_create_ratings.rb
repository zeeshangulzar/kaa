class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer   :user_id
      t.integer   :rateable_id
      t.string    :rateable_type, :limit => 75
      t.integer    :score
      t.timestamps
    end

    add_index :ratings, :user_id
    add_index :ratings, [:rateable_type, :rateable_id], :name => :rateable_idx
  end
end