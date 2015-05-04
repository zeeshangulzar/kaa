class TeamInviteEmail
  @queue = :default

  def self.perform(invite_type, to_id, from_id)
    ActiveRecord::Base.verify_active_connections!
    to_user = User.find(to_id) rescue nil
    from_user = User.find(from_id) rescue nil
    if to_user && from_user
      GoMailer.team_invite_email(invite_type, to_user, from_user).deliver!
    end
  end
end
