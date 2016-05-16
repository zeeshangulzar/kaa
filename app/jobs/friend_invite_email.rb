class FriendInviteEmail
  @queue = :default

  def self.perform(invitee_id, inviter_id)
    ActiveRecord::Base.verify_active_connections!
    invitee = User.find(invitee_id) rescue nil
    inviter = User.find(inviter_id) rescue nil
    if invitee && inviter
      GoMailer.friend_invite_email(invitee, inviter).deliver!
    end
  end
end
