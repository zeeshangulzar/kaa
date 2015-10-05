class AddPromotionIdToTeams < ActiveRecord::Migration
  def up
    add_column :teams, :promotion_id, :integer
    add_index :teams, :promotion_id
    Team.all.each{|team|
      team.promotion_id = team.competition.promotion_id
      team.save!
    }
  end
  def down
    remove_index :teams, :promotion_id
    remove_column :teams, :promotion_id
  end
end
