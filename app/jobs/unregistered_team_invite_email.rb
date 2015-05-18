class UnregisteredTeamInviteEmail
  @queue = :default

  def self.perform(email, inviter_id, team_id, message = nil)
    ActiveRecord::Base.verify_active_connections!
    inviter = User.find(inviter_id) rescue nil
    team = Team.find(team_id) rescue nil
    if inviter && team
      GoMailer.unregistered_team_invite_email(email, inviter, team, message).deliver!
    end
  end
end
