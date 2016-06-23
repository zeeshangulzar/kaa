ActiveRecord::Base.transaction do

raise 'this already ran' if !Promotion.find_by_subdomain('www').nil?

startDt = Date.new(2016, 1, 1)

reseller = Reseller.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

organization = reseller.organizations.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

promotion = organization.promotions.create :name=>"Health Enhancement Systems", :subdomain=>'www', :is_active=>1, :program_length => 3650, :starts_on => startDt, :registration_starts_on => startDt, :launch_on => startDt
promotion.save!

location1 = promotion.locations.create :name => '800 Cambridge', :parent_location_id => nil

activity_steps_point_1 = promotion.point_thresholds.create :value => 1, :min => 4000, :rel => "STEPS", :color => '#55a746'
activity_steps_point_2 = promotion.point_thresholds.create :value => 2, :min => 6000, :rel => "STEPS", :color => '#ff7c01'
activity_steps_point_3 = promotion.point_thresholds.create :value => 3, :min => 8000, :rel => "STEPS", :color => '#00a19b'
activity_steps_point_4 = promotion.point_thresholds.create :value => 4, :min => 10000, :rel => "STEPS", :color => '#bb1654'

activity_minutes_point_1 = promotion.point_thresholds.create :value => 1, :min => 15, :rel => "MINUTES", :color => '#55a746'
activity_minutes_point_2 = promotion.point_thresholds.create :value => 2, :min => 30, :rel => "MINUTES", :color => '#ff7c01'
activity_minutes_point_3 = promotion.point_thresholds.create :value => 3, :min => 45, :rel => "MINUTES", :color => '#00a19b'
activity_minutes_point_4 = promotion.point_thresholds.create :value => 4, :min => 60, :rel => "MINUTES", :color => '#bb1654'

promotion.save!

ex_activity_biking = promotion.exercise_activities.create  :name => "Biking", :summary => "Riding your bike"
ex_activity_biking.save!

ex_activity_walking = promotion.exercise_activities.create :name => "Walking", :summary => "Going for a walk"
ex_activity_walking.save!

ex_activity_swim = promotion.exercise_activities.create :name => "Swimming", :summary => "Moving through water while floating"
ex_activity_swim.save!

behavior_water = promotion.behaviors.create :name => "Drink Water", :content => "You need to drink water", :summary => 'Water water water'
behavior_water.save!

behavior_veggies = promotion.behaviors.create :name => "Eat Veggies", :content => "Gots to have those veggies", :summary => 'Veggies veggies veggies'
behavior_veggies.save!

master = promotion.users.build
master.role=User::Role[:master]
master.password = 'test'
master.email = 'admin@hesapps.com'
master.location = location1
if master.save
  master_profile = master.create_profile :first_name => 'HES', :last_name => 'Admin'
end

user = promotion.users.build
user.role = User::Role[:user]
user.password = 'test'
user.email = 'benm@hesonline.com'
user.location = location1
if user.save
  user_profile = user.create_profile :first_name => 'Ben', :last_name => 'Murphy', :started_on => (startDt + 7), :registered_on => (startDt + 7)
  #Override the defaults and have this user start in the past... for seeding purposes
  user_profile.started_on = (startDt + 7)
  user_profile.save!
end

user2 = promotion.users.build
user2.role = User::Role[:user]
user2.password = 'test'
user2.email = 'bobb@hesonline.com'
user2.username = 'bobb'
user2.location = location1
if user2.save
  user2_profile = user2.create_profile :first_name => 'Bob', :last_name => 'Baldwin', :started_on => (startDt), :registered_on => (startDt)
  #Override the defaults and have this user start in the past... for seeding purposes
  user2_profile.started_on = (startDt)
  user2_profile.save!
end

user3 = promotion.users.build
user3.role = User::Role[:user]
user3.password = 'test'
user3.email = 'jakes@hesonline.com'
user3.username = 'jakes'
user3.location = location1
if user3.save
  user3_profile = user3.create_profile :first_name => 'Jake', :last_name => 'Smith', :started_on => (startDt + 7), :registered_on => (startDt + 7)
  #Override the defaults and have this user start in the past... for seeding purposes
  user3_profile.started_on = (startDt + 7)
  user3_profile.save!
end

user4 = promotion.users.build
user4.role = User::Role[:user]
user4.password = 'test'
user4.email = 'drewp@hesonline.com'
user4.username = 'drewp'
user4.location = location1
if user4.save
  user4_profile = user4.create_profile :first_name => 'Drew', :last_name => 'Papworth', :started_on => (startDt + 14), :registered_on => (startDt + 14)
  #Override the defaults and have this user start in the past... for seeding purposes
  user4_profile.started_on = (startDt + 7)
  user4_profile.save!
end

user5 = promotion.users.build
user5.role = User::Role[:user]
user5.password = 'test'
user5.email = 'richardw@hesonline.com'
user5.username = 'richardw'
user5.location = location1
if user5.save
  user5_profile = user5.create_profile :first_name => 'Richard', :last_name => 'Wardin', :started_on => (startDt + 7), :registered_on => (startDt + 7)
  #Override the defaults and have this user start in the past... for seeding purposes
  user5_profile.started_on = (startDt + 7)
  user5_profile.save!
end

user6 = promotion.users.build
user6.role = User::Role[:user]
user6.password = 'test'
user6.email = 'miker@hesonline.com'
user6.username = 'miker'
user6.location = location1
if user6.save
  user6_profile = user6.create_profile :first_name => 'Mike', :last_name => 'Robertson', :started_on => (startDt + 7), :registered_on => (startDt + 7)
  #Override the defaults and have this user start in the past... for seeding purposes
  user6_profile.started_on = (startDt + 7)
  user6_profile.save!
end

user7 = promotion.users.build
user7.role = User::Role[:user]
user7.password = 'test'
user7.email = 'brianl@hesonline.com'
user7.username = 'brianl'
user7.location = location1
if user7.save
  user7_profile = user7.create_profile :first_name => 'Brian', :last_name => 'Ludwig', :started_on => (startDt + 7), :registered_on => (startDt + 7)
  #Override the defaults and have this user start in the past... for seeding purposes
  user7_profile.started_on = (startDt + 7)
  user7_profile.save!
end


#Build up user entries

entry_1 = user.entries.build(:recorded_on => user.profile.started_on, :exercise_minutes => nil)
entry_1.save!
entry_1.entry_behaviors.build(:behavior_id => behavior_water.id, :value => 1)
entry_1.save_exercise_activity(ex_activity_biking, :value => 28)
entry_1.exercise_minutes = 28
entry_1.save!

entry_2 = user.entries.build(:recorded_on => user.profile.started_on + 1 , :exercise_steps => 10302, :exercise_minutes => nil)
entry_2.save!

end
