class ChangeExpiresOnFormatInChallengesReceived < ActiveRecord::Migration
  def up
    change_column :challenges_received, :expires_on, :datetime
  end

 def down
   change_column :challenges_received, :expires_on, :date
 end
end
