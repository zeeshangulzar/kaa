reseller = Reseller.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

organization = reseller.organizations.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

promotion = organization.promotions.create :name=>"Health Enhancement Systems", :subdomain=>'www'

master = promotion.users.build
master.role=User::Role[:master]
master.password = 'test'
master.email = 'admin@hesapps.com'
master.save
master_profile = master.create_profile :first_name => 'HES', :last_name => 'Admin'

user = promotion.users.build
user.role = User::Role[:user]
user.password = 'test'
user.email = 'johns@hesonline.com'
user.save
user_profile = user.create_profile :first_name => 'John', :last_name => 'Stanfield'

puts "to make testing easy, auth-basic headers are below"
User.all.each do |user|
  puts user.email
  puts user.auth_basic_header 
end
