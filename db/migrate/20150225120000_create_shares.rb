class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer   :user_id
      t.integer   :shareable_id
      t.string    :shareable_type, :limit => 75
      t.string    :via
      t.timestamps
    end

    add_index :shares, :user_id
    add_index :shares, [:shareable_type, :shareable_id], :name => :shareable_idx
  end
end