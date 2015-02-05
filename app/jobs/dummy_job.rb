class DummyJob
  @queue = :default

  def self.perform(entry_id)
    entry = Entry.find(entry_id)
    GoMailer.dummy_email(entry).deliver!
  end
end
