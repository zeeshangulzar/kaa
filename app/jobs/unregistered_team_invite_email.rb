class UnregisteredTeamInviteEmail
  @queue = :default

  def self.perform(email, inviter_id, message = nil)
    ActiveRecord::Base.verify_active_connections!
    inviter = User.find(inviter_id) rescue nil
    if inviter
      GoMailer.unregistered_team_invite_email(email, inviter, message).deliver!
    end
  end
end
