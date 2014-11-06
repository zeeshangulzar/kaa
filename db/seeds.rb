reseller = Reseller.create :name=>"Health Enhancement Systems"

organization = reseller.organizations.create :name=>"Health Enhancement Systems"

promotion = organization.promotions.create :name=>"Health Enhancement Systems", :subdomain=>'www'

master = promotion.users.build
master.role=User::Role[:master]
master.password = 'test'
master.save
master_contact = master.create_contact :first_name => 'HES', :last_name => 'Admin', :email => 'admin@hesapps.com'

user = promotion.users.build
user.role = User::Role[:user]
user.password = 'test'
user.save
user_contact = user.create_contact :first_name => 'John', :last_name => 'Stanfield', :email => 'johns@hesonline.com'

puts "to make testing easy, auth-basic headers are below"
User.all.each do |user|
  puts user.contact.email
  puts user.auth_basic_header 
end
