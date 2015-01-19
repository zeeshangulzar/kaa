promotion = Promotion.first
location1 = promotion.locations.first
msgs = []

# RANDOMLY LOG A BUNCH OF DATA AND SEE IF BADGES BREAK
badge_user = promotion.users.build
badge_user.role = User::Role[:user]
badge_user.password = 'test'
badge_user.email = "#{SecureRandom.hex}@example.com"
badge_user.username = 'badge'
badge_user.auth_key = 'changemebadge'
badge_user.location = location1
if badge_user.save
  badge_user_start_date = Date.new(2014,1,1)
  badge_user_profile = badge_user.create_profile :first_name => 'Wilhelm', :last_name => 'WeekendWarrior', :registered_on => badge_user_start_date
  badge_user_profile.started_on = badge_user_start_date
  badge_user_profile.save!

  # log 365 days, but in a random order
  (0..365).to_a.shuffle.each do |t|
    e=badge_user.entries.build :recorded_on=>badge_user_start_date+t.to_i
    e.exercise_minutes = (rand * 90).to_i
    e.save
  end

  msgs << "logged #{badge_user.entries.count} days for #{badge_user.email} and badges are: #{badge_user.badges.reload.collect(&:badge_key).join(', ')}"
end



# NOW TEST WHETHER THEY WORK IN KNOWN CIRCUMSTANCES

def verify_weekend_warrior(badge_user,expected_earned_date,expected_total_warrior_badges,reason)
  warrior = badge_user.badges.reload.detect{|b|b.badge_key==Badge::WeekendWarrior && b.earned_date == expected_earned_date} 
  if warrior
    if badge_user.badges.select{|b|b.badge_key==Badge::WeekendWarrior}.size == expected_total_warrior_badges
      # bacon pancaaaaaaaaakes
      return true
    else
      puts "boo!  weekend warrior badge doesn't work!  (#{reason})  badges below"
      puts y(badge_user.badges)
      return false
    end
  else
    puts "boo!  weekend warrior badge doesn't work!  (#{reason}, badge not earned for #{expected_earned_date}).  badges below"
    puts y(badge_user.badges)
      return false
  end
end

badge_user = promotion.users.build
badge_user.role = User::Role[:user]
badge_user.password = 'test'
badge_user.email = "#{SecureRandom.hex}@example.com"
badge_user.username = 'badge2'
badge_user.auth_key = 'changemebadge2'
badge_user.location = location1
if badge_user.save
  badge_user_start_date = Date.new(2014,1,1)
  badge_user_profile = badge_user.create_profile :first_name => 'Winchester', :last_name => 'WeekendWarrior', :registered_on => badge_user_start_date
  badge_user_profile.started_on = badge_user_start_date
  badge_user_profile.save!

  first_saturday_of_2014 = Date.new(2014,1,4)

  # throw in some non-weekend entries
  90.times do
    i = (rand * 365).to_i
    unless [0,6].include?((first_saturday_of_2014+i).wday)
      e=badge_user.entries.build :recorded_on=>first_saturday_of_2014+i
      e.exercise_minutes = (rand * 60).to_i
      e.save
    end
  end

  e=badge_user.entries.build :recorded_on=>first_saturday_of_2014+350
  e.exercise_minutes = (rand * 60).to_i
  e.save
  weekenders = badge_user.badges.reload.select{|b|b.badge_key==Badge::Weekender && b.earned_date == first_saturday_of_2014+350}
  if weekenders.size == 1
    # stroke it to the east, and stroke it to the west!
  else
    puts "boo!  weekender badge doesn't work! (earned #{weekenders.size} badges). badges below"
    puts y(badge_user.badges)
    return
  end

  # if you want to watch the date change... sleep for 30 seconds, copy the query, paste it... then run again when this script continues.  weekender badge should move from 2014-12-20 to 2014-01-04
  #sleep(30)

  # log 5 consecutive weekends...
  warrior_in_week_5 = [1,2,3,4,5]
  
  warrior_in_week_5.each do |week|
    e=badge_user.entries.build :recorded_on=>first_saturday_of_2014+((week-1)*7)
    e.exercise_minutes = (rand * 60).to_i
    e.save
  end
  
  # confirm weekender badge...
  weekenders = badge_user.badges.reload.select{|b|b.badge_key==Badge::Weekender && b.earned_date == first_saturday_of_2014}
  if weekenders.size == 1
    # stroke it to the east, and stroke it to the west!
  else
    puts "boo!  weekender badge doesn't work! weekender badge earned_date was supposed to move from #{first_saturday_of_2014+350} to #{first_saturday_of_2014}. (earned #{weekenders.size} badges). badges below"
    puts y(badge_user.badges)
    return
  end
  return unless verify_weekend_warrior(badge_user,first_saturday_of_2014+28,1,"first test -- logged 5 consecutive weekends")

  # delete an entry to break the streak, then see if the badge went away (it should)
  badge_user.entries.where(:recorded_on=>first_saturday_of_2014+14).first.destroy
  warriors = badge_user.badges.reload.select{|b|b.badge_key==Badge::WeekendWarrior}
  if warriors.empty?
  else
    puts "boo!  weekend warrior badge doesn't work!  (logged 5 consecutive weekends, then deleted entry for 3rd week, still have #{warriors.size} badges).  badges below"
    puts y(badge_user.badges)
  end 

  # log more consecutive weekends...
  seventh_saturday_of_2014 = Date.new(2014,3,1)
  warrior_in_week_5 = [1,2,3,4,5]
  
  warrior_in_week_5.each do |week|
    e=badge_user.entries.build :recorded_on=>seventh_saturday_of_2014+((week-1)*7)
    e.exercise_minutes = (rand * 60).to_i
    e.save
  end
  return unless verify_weekend_warrior(badge_user,seventh_saturday_of_2014+28,1,"second test -- logged 5 consecutive weekends starting march 1")

  # log more consecutive weekends...
  some_saturday_of_2014 = Date.new(2014,4,26)
  warrior_in_week_5 = [1,2,3,4,5,6,7,8,9]
  
  warrior_in_week_5.each do |week|
    e=badge_user.entries.build :recorded_on=>some_saturday_of_2014+((week-1)*7)
    e.exercise_minutes = (rand * 60).to_i
    e.save
  end
  return unless verify_weekend_warrior(badge_user,some_saturday_of_2014+28,2,"third test -- logged 9 consecutive weekends")

  # log the 10th weekend in a row to get another badge
  e=badge_user.entries.build :recorded_on=>some_saturday_of_2014+63
  e.exercise_minutes = (rand * 60).to_i
  e.save
  return unless verify_weekend_warrior(badge_user,some_saturday_of_2014+63,3,"fourth test -- logged 10 consecutive weekends")

  # now delete the badges and see if they can be put back
  badges_before_delete = badge_user.badges.find(:all,:order=>'badge_key,sequence').collect{|badge|[badge.badge_key,badge.sequence,badge.earned_date]}
  Badge.connection.execute "delete from badges where user_id = #{badge_user.id}"
  badge_user.entries.where(:recorded_on=>some_saturday_of_2014).first.save
  badges_after_delete = badge_user.badges.find(:all,:order=>'badge_key,sequence').collect{|badge|[badge.badge_key,badge.sequence,badge.earned_date]}
  if badges_before_delete == badges_after_delete
    # they were put back the same way they were before they were deleted
  else
    puts "boo! badges don't get put back the same way they were before delete. badges below"
    puts "===before delete==="
    puts y(badges_before_delete)
    puts "===after delete==="
    puts y(badges_after_delete)
  end

  # now delete random badges and see if they can be put back
  badges_before_delete = badge_user.badges.find(:all,:order=>'badge_key,sequence').collect{|badge|[badge.badge_key,badge.sequence,badge.earned_date]}
  badge_user.badges.find(:all,:order=>'badge_key,sequence').each_with_index{|badge,i| badge.destroy if i%2==1}
  badges_post_delete = badge_user.badges.find(:all,:order=>'badge_key,sequence').collect{|badge|[badge.badge_key,badge.sequence,badge.earned_date]}
  badge_user.entries.where(:recorded_on=>some_saturday_of_2014).first.save
  badges_after_delete = badge_user.badges.find(:all,:order=>'badge_key,sequence').collect{|badge|[badge.badge_key,badge.sequence,badge.earned_date]}
  if badges_before_delete == badges_after_delete
    # they were put back the same way they were before they were deleted
  else
    puts "boo! badges don't get put back the same way they were before delete. badges below"
    puts "===before delete==="
    puts y(badges_before_delete)
    puts "===post delete==="
    puts y(badges_post_delete)
    puts "===after delete==="
    puts y(badges_after_delete)
  end


  msgs << "logged #{badge_user.entries.count} days for #{badge_user.email} and badges are: #{badge_user.badges.reload.collect(&:badge_key).join(', ')}"
end

msgs << "badges script completed...  look for lines that start with boo!"

puts msgs.join("\n")
