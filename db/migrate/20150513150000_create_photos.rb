class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string    :name
      t.string    :caption
      t.text      :description
      t.string    :image
      t.boolean   :flagged
      t.integer   :flagged_by
      t.integer   :user_id
      t.string    :photoable_type
      t.integer   :photoable_id
      t.timestamps
    end

    add_index :photos, :user_id
    add_index :photos, [:photoable_type, :photoable_id], :name => :photoable_idx
  end
end