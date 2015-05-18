class TeamInviteEmail
  @queue = :default

  def self.perform(invite_type, to_id, from_id, team_id, message = nil)
    ActiveRecord::Base.verify_active_connections!
    to_user = User.find(to_id) rescue nil
    from_user = User.find(from_id) rescue nil
    team = Team.find(team_id) rescue nil
    if to_user && from_user && team
      GoMailer.team_invite_email(invite_type, to_user, from_user, team, message).deliver!
    end
  end
end
