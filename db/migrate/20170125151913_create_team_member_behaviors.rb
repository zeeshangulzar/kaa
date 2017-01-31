class CreateTeamMemberBehaviors < ActiveRecord::Migration
  def change
    create_table :team_member_behaviors do |t|
      t.references :team_member, :behavior
      t.date :recorded_on
      t.boolean :is_recorded
      t.string :value
      t.float :points
      t.timestamps
    end
  end
end


