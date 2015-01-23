class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.integer     :promotion_id
      t.string      :name
      t.text        :description
      t.text        :completion_message
      t.string      :image
      t.string      :badge_type
      t.integer     :point_goal
      t.integer     :sequence
      t.timestamps
    end
  end
end


=begin
class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.references   :user
      t.string       :badge_key, :limit=>25
      t.integer      :sequence
      t.integer      :earned_year
      t.date         :earned_date

      t.timestamps
    end

    execute "alter table badges modify id bigint auto_increment"

    add_index :badges, [:user_id,:badge_key,:earned_year,:sequence], :name => "by_user_id_and_badge_key_and_sequence_and_earned_year_unique", :unique => true
  end
end
=end