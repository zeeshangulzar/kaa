HesReactor::Subscribers.define do

  ######################
  # Promotions
  ######################


  ######################
  # Users
  ######################


  ######################
  # Entries
  ######################

  subscribe :entry, :before_save do |entry|

    
  end

  subscribe :entry, :after_save do |entry|
    entry.update_column(:updated_at, Time.now)
  end

end