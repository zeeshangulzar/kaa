class ChallengeReceivedEmail
  @queue = :default

  def self.perform(challenge_sent_id, receiver_id)
    ActiveRecord::Base.verify_active_connections!
    challenge_sent = ChallengeSent.find(challenge_sent_id) rescue nil
    receiver = User.find(receiver_id) rescue nil
    if challenge_sent && receiver
      GoMailer.challenge_received_email(challenge_sent, receiver).deliver!
    end
  end
end
