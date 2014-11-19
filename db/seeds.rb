reseller = Reseller.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

organization = reseller.organizations.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

promotion = organization.promotions.create :name=>"Health Enhancement Systems", :subdomain=>'www', :is_active=>1, :program_length => 56, :starts_on => Date.today - 1

# activity_steps = promotion.activities.create :name =>"Steps", :content=>"**4000-5999 steps = 1 point** **6000-7999 = 2 points ** **8000 - 9999 = 3 points ** **10,000+ steps = 4 points ** Aim for 10,000 steps or more a day for the greatest health benefits &mdash; such as more energy, better mood, weight control, and lower risk for many chronic conditions.", 
#  :type_of_prompt => "textbox", :cap_value => 25000, :cap_message =>"You can log up to 25,000 steps per day."

# activity_steps_point_1 = activity_steps.point_thresholds.create :value => 1, :min => 4000
# activity_steps_point_2 = activity_steps.point_thresholds.create :value => 2, :min => 6000
# activity_steps_point_3 = activity_steps.point_thresholds.create :value => 3, :min => 8000
# activity_steps_point_4 = activity_steps.point_thresholds.create :value => 4, :min => 10000

#  activity_minutes = promotion.activities.create :name =>"Exercise Minutes", :content=>"**15-29 minutes = 1 point** **30-44 minutes = 2 points ** **45-59 minutes = 3 points ** **60+ minutes = 4 points ** Aim for 60 exercise minutes or more a day for the greatest health benefits &mdash; such as more energy, better mood, weight control, and lower risk for many chronic conditions.", 
#  :type_of_prompt => "textbox", :cap_value => 360, :cap_message =>"You can log up to 360 minutes per day."


# activity_minutes_point_1 = activity_minutes.point_thresholds.create :value => 1, :min => 15
# activity_minutes_point_2 = activity_minutes.point_thresholds.create :value => 2, :min => 30
# activity_minutes_point_3 = activity_minutes.point_thresholds.create :value => 3, :min => 45
# activity_minutes_point_4 = activity_minutes.point_thresholds.create :value => 4, :min => 60

# activity_biking = activity_minutes.child_activities.create  :name => "Biking", :content => "Riding your bike", :type_of_prompt => "textboxx"
# activity_walking = activity_minutes.child_activities.create :name => "Walking", :content => "Going for a walk", :type_of_prompt => "textboxx"
# activity_swim = activity_minutes.child_activities.create :name => "Swimming", :content => "Moving through water while floating", :type_of_prompt => "textboxx"

activity_water = promotion.activities.create :name => "Drink Water", :content => "You need to drink water", :type_of_prompt => "counter", :cap_value => 8, :cap_message => "You can only record 8 glasses of water"

timed_water_activity = activity_water.timed_activities.create :begin_date => Date.today, :end_date => (Date.today + 1)

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
  user_profile = user.create_profile :first_name => 'John', :last_name => 'Stanfield', :started_on => Date.today, :registered_on => Date.today
end

puts "to make testing easy, auth-basic headers are below"
User.all.each do |user|
  puts user.email
  puts user.auth_basic_header 
end
