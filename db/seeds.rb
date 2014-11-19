reseller = Reseller.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

organization = reseller.organizations.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

promotion = organization.promotions.create :name=>"Health Enhancement Systems", :subdomain=>'www', :is_active=>1, :program_length => 56, :starts_on => Date.today - 15

activity_steps_point_1 = promotion.point_thresholds.create :value => 1, :min => 4000, :rel => "STEPS"
activity_steps_point_2 = promotion.point_thresholds.create :value => 2, :min => 6000, :rel => "STEPS"
activity_steps_point_3 = promotion.point_thresholds.create :value => 3, :min => 8000, :rel => "STEPS"
activity_steps_point_4 = promotion.point_thresholds.create :value => 4, :min => 10000, :rel => "STEPS"

activity_minutes_point_1 = promotion.point_thresholds.create :value => 1, :min => 15, :rel => "MINUTES"
activity_minutes_point_2 = promotion.point_thresholds.create :value => 2, :min => 30, :rel => "MINUTES"
activity_minutes_point_3 = promotion.point_thresholds.create :value => 3, :min => 45, :rel => "MINUTES"
activity_minutes_point_4 = promotion.point_thresholds.create :value => 4, :min => 60, :rel => "MINUTES"

promotion.save!

ex_activity_biking = promotion.exercise_activities.create  :name => "Biking", :summary => "Riding your bike"
ex_activity_biking.save!

ex_activity_walking = promotion.exercise_activities.create :name => "Walking", :summary => "Going for a walk"
ex_activity_walking.save!

ex_activity_swim = promotion.exercise_activities.create :name => "Swimming", :summary => "Moving through water while floating"
ex_activity_swim.save!

activity_water = promotion.activities.create :name => "Drink Water", :content => "You need to drink water", :type_of_prompt => "counter", :cap_value => 8, :cap_message => "You can only record 8 glasses of water"
activity_water.save!

activity_veggies = promotion.activities.create :name => "Eat Veggies", :content => "Gots to have those veggies", :type_of_prompt => "counter", :cap_value => 5, :cap_message => "You can only record 5 veggie servings a day"
activity_veggies.save!


timed_water_activity = activity_water.timed_activities.create :begin_date => Date.today - 2, :end_date => (Date.today + 20)
timed_water_activity.point_thresholds.create :value => 1, :min => 1
timed_water_activity.save!

timed_water_activity_2 = activity_water.timed_activities.create :begin_date => Date.today + 32, :end_date => (Date.today + 50)
timed_water_activity_2.point_thresholds.create :value => 1, :min => 4
timed_water_activity_2.point_thresholds.create :value => 2, :min => 8
timed_water_activity_2.save!

master = promotion.users.build
master.role=User::Role[:master]
master.password = 'test'
master.email = 'admin@hesapps.com'
master.username = 'admin'
if master.save
  master_profile = master.create_profile :first_name => 'HES', :last_name => 'Admin'
end

user = promotion.users.build
user.role = User::Role[:user]
user.password = 'test'
user.email = 'johns@hesonline.com'
user.username = 'johns'
if user.save
  user_profile = user.create_profile :first_name => 'John', :last_name => 'Stanfield', :started_on => (Date.today - 7), :registered_on => (Date.today - 7)

  #Override the defaults and have this user start in the past... for seeding purposes
  user_profile.started_on = (Date.today - 7)
end
user_profile.save!

#Build up user entries

entry_1 = user.entries.build(:recorded_on => user.profile.started_on, :exercise_steps => 10302, :exercise_minutes => nil)
entry_1.save!
entry_1.entry_activities.build(:activity_id => activity_water.id, :value => 1)
entry_1.save_exercise_activity(ex_activity_biking, :value => 28)
entry_1.exercise_minutes = 28
entry_1.save!

entry_2 = user.entries.build(:recorded_on => user.profile.started_on + 1 , :exercise_steps => 10302, :exercise_minutes => nil)
entry_2.save!

puts "to make testing easy, auth-basic headers are below"
User.all.each do |user|
  puts user.email
  puts user.auth_basic_header 
end
