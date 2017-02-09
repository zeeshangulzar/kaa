# go to the bottom of the file :)

require 'securerandom'

def new_admin_profile
  return Profile.new(
    :first_name => "HES",
    :last_name => "Administrator",
    :phone => "989.839.0852",
    :line1 => "110 E Grove St",
    :city => "Midland",
    :state_province => "MI",
    :postal_code => "48640"
  )
end

def new_wallexpert_profile
  return Profile.new(
    :first_name => "HES",
    :last_name => "Wall Expert",
    :phone => "989.839.0852",
    :line1 => "110 E Grove St",
    :city => "Midland",
    :state_province => "MI",
    :postal_code => "48640"
  )
end

def create_www_promotion
  # Create the default reseller, org and promotion
  r = Reseller.create( :name => "Health Enhancement Systems", :contact_name => "HES", :contact_email => "admin@hesapps.com")
  o = r.organizations.create(:name => "Health Enhancement Systems", :contact_name => "HES", :contact_email => "admin@hesapps.com")

  p = o.promotions.new(
    :name                   => "Default Promotion",
    :program_name           => "Keep America Active",
    :subdomain              => "www",
    :launch_on              => Date.today,
    :starts_on              => Date.today,
    :registration_starts_on => Date.today
  )

  p.save!

  master = p.users.create(:profile => new_admin_profile, :role => User::Role[:master], :password => "test", :email => "admin@hesapps.com")
  poster = p.users.create(:profile => new_wallexpert_profile, :role => User::Role[:poster], :password => "test", :email => "wallexpert@hesapps.com")

  puts "created www promotion"
end

def get_lorem_ipsum(n=10)
  words = %w(Proin congue quis libero eget tempus Integer neque ligula, pulvinar vel quam non, tristique pulvinar neque Nunc vel pharetra mi, sit amet molestie tortor Sed finibus suscipit ex Nam dapibus faucibus mauris Mauris blandit magna in ex dignissim, in cursus ligula condimentum Vestibulum consequat eros augue, vel pulvinar turpis tincidunt in Ut vitae nibh erat Aenean blandit dapibus pulvinar Sed at libero non arcu egestas iaculis pellentesque a dui Quisque ornare nisi eu maximus laoreet Nulla vitae euismod nisl Phasellus luctus pulvinar magna, vel consequat urna tincidunt quis Morbi et condimentum lacus Ut nec magna eleifend, efficitur ipsum ac, tincidunt erat Cras ornare lorem nec justo eleifend tempor n sagittis odio feugiat, sagittis eros et, pretium metus Praesent eget lacus libero Maecenas et sapien condimentum, sollicitudin neque vitae, vestibulum neque Cras laoreet condimentum diam a consectetur Sed gravida malesuada aliquam Maecenas rutrum eu ex nec mollis Cras sed scelerisque nunc Nulla sed placerat nisl Sed metus augue, fermentum vel metus congue, faucibus cursus metus Aenean tempus ante at velit rutrum convallis Quisque posuere nisi ac mi mattis, sit amet commodo mauris ullamcorper Donec fringilla nunc turpis, rutrum egestas ex vulputate a Vivamus fermentum odio ligula, eu tincidunt sapien dictum quis enean lobortis eu libero faucibus pellentesque Praesent lobortis suscipit justo sed ultricies Donec at dui in eros lacinia vulputate Aliquam eget ultricies eros Praesent vitae nulla id urna hendrerit dapibus vel eu augue Aenean fringilla, velit vitae elementum tempus, nisl magna bibendum nisi, eget ullamcorper tortor turpis eget enim Quisque a blandit turpis Nunc tortor orci, hendrerit non pharetra non, euismod semper quam Proin blandit nulla eu ante accumsan congue Fusce est nunc, facilisis et malesuada nec, lobortis ac tortor Fusce est quam, faucibus nec eros ultricies, malesuada commodo justo Mauris consectetur, dui sit amet elementum laoreet, sem elit faucibus turpis, non dictum risus erat eget tellus Maecenas vitae felis a magna hendrerit porta In scelerisque neque semper turpis venenatis, vitae sodales velit porttitor Vivamus ac justo malesuada, egestas felis et, tincidunt sem Donec sed velit vel metus gravida posuere Pellentesque lacus velit, posuere vitae suscipit a, luctus eu diam Interdum et malesuada fames ac ante ipsum primis in faucibus Donec sagittis, augue sit amet placerat consequat, risus dui auctor diam, at condimentum arcu nisl et risus Aliquam ut vulputate est Donec nisl justo, gravida nec ultrices et, maximus mattis nibh Aliquam erat volutpat Proin scelerisque pharetra sagittis Nunc dictum ipsum faucibus turpis aliquet, et fermentum velit dignissim Mauris vel dolor at est ultrices luctus ut at urna Duis eget purus libero Suspendisse placerat, enim id tempus condimentum, turpis diam facilisis sem, sed pellentesque purus magna vitae ligula Maecenas at finibus elit, vitae posuere ipsum Vivamus porttitor, nunc ac sagittis tempor, erat magna mattis tellus, vitae pharetra urna nisl vel lorem Maecenas a massa vel eros mattis volutpat at quis neque Nulla pulvinar arcu eu mattis finibus Fusce nec rhoncus ligula)
  words.shuffle.first(n).join(' ').downcase
end

def get_fake_team_names(n=4)
  adjectives = %w(cuddly open kaput gusty complex observant near confused furry defective meaty violet entertaining marvelous white boiling violet shivering well-off wholesale subdued absorbing alluring phobic tangible adhesive deeply nostalgic detailed wanting abject silent abashed illegal ahead shaky )
  nouns = %w(Accident Notebook Ottoman Cookie Great-grandfather Opportunity Player Sandals Switchboard Wetsuit sloth iguana peccary wolverine panther lemur)
  arr = []
  n.times do
    arr << "#{adjectives.shuffle.first((rand * 3.0).ceil).join(' ')} #{nouns.shuffle.first.pluralize}".titleize 
  end
  arr
end

def get_fake_names(n=1000)
  fn = ActiveRecord::Base.connection.select_all("select firstname from fake_data_first_name order by rand() limit #{n}")
  ln = ActiveRecord::Base.connection.select_all("select lastname from fake_data_last_name order by rand() limit #{n}")
  arr = []
  n.times do |i|
    fn.shuffle! if i % fn.size == 0
    ln.shuffle! if i % ln.size == 0
    arr << [fn[i % fn.size]['firstname'],ln[i % ln.size]['lastname']]
  end
  arr
end

def get_random_color
  %w(black blue green yellow cyan white magenta red).shuffle.first
end

def get_random_food
  %w(Coffee Sushi Macaroni Pizza Bagels Pie).shuffle.first
end

def get_random_custom_prompts(n=1)
  [
    {:prompt=>"What is your favorite color?",:data_type=>'string',:type_of_prompt=>CustomPrompt::TEXTBOX,:short_label=>'Favorite color'},
    {:prompt=>"What is your favorite food?",:data_type=>'string',:type_of_prompt=>CustomPrompt::TEXTBOX,:short_label=>'Favorite food'},
    {:prompt=>"What health topics would you like to learn more about?",:data_type=>'text',:type_of_prompt=>CustomPrompt::MULTILINETEXTBOX,:short_label=>'Health topics'},
    {:prompt=>"What is your age group?",:data_type=>'string',:type_of_prompt=>CustomPrompt::DROPDOWN,:short_label=>'Age group',:options=>"Under 13\n14-17\n18-24\n25-39\n40-49\n50+"},
    {:prompt=>"What is your employee mailbox number?",:data_type=>'integer',:type_of_prompt=>CustomPrompt::TEXTBOX,:short_label=>'Mailbox number'},
    {:prompt=>"I am an employee",:data_type=>'string',:type_of_prompt=>CustomPrompt::CHECKBOX,:short_label=>'Is Employee'}
  ].shuffle.first(n)
end

def log_entries(u)
   User.transaction do
     (u.promotion.launch_on..Date.today).each{|date|
       u.entries.create(:recorded_on => date, :exercise_steps => rand(15000))
     }
   end
end

def create_test_promotion(attrs={})
  r = Reseller.first
  o = r.organizations.first

  defaults = {
    :program_name => "Keep America Active",
    :subdomain => SecureRandom.hex(5),
    :launch_on => Date.today-14,
    :is_registration_frozen => false
  }
  defaults[:name] = defaults[:subdomain]

  map = Map.all.detect{|m|m.name=='Default'} || Map.first

  defaults[:route_id] = map.routes.first.id if map

  p_attrs = defaults.merge(attrs)

  p = o.promotions.find(:first,:conditions=>"subdomain = '#{p_attrs[:subdomain]}'")
  p.destroy if p
  
  p = o.promotions.build(p_attrs)
  p.flags[:is_show_individual_leaderboard] = true
  yield p if block_given?
  p.save

  get_random_custom_prompts(2).each do |hash|
    cp = p.custom_prompts.create hash
    p.evaluations.each do |ev|
      ev.save_custom_prompt(cp)
    end
  end

  puts "created #{p.subdomain} promotion"

  p
end

def create_test_user(promotion,attrs={})
  u = promotion.users.create(attrs)
  u.opted_in_individual_leaderboard = promotion.flags[:show_individual_leaderboard] && (rand * 10 <= 8)
  u.save 
  profile = u.profile
  profile.started_on = promotion.launch_on
  profile.save
  log_entries(u)

  u
end


def create_logging_promotion(subdomain='logging')
  p = create_test_promotion(:subdomain=>subdomain,:registration_starts_on=>Date.today-7,:registration_ends_on=>Date.today+365,:late_registration_ends_on=>Date.today+400,:starts_on=>(Date.today-7).beginning_of_week)
  n = 50
  names = get_fake_names(n)
  n.times do |t|
    User.transaction do
      u = create_test_user(p, {:profile => Profile.new(:first_name=>names[t].first, :last_name=>names[t].last), :email => "#{names[t].first}.#{names[t].last}@example.hes", :password => "test"})
      u.profile.update_attributes :gender => (t < 30 ? 'F' : 'M')
    end
    puts "created 10 users...OK" if t > 0 && t % 10 == 0
  end
  puts "created #{n} users!"

  p
end

def add_fake_teams(competition,n=4)
  team_names = get_fake_team_names(n) 
  unassigned_users = ActiveRecord::Base.connection.select_all("select distinct users.id from users left join team_memberships on team_memberships.user_id = users.id where users.promotion_id = #{competition.promotion_id} and (team_memberships.id is null or team_memberships.status = 0) order by rand()").collect{|row|row['id']}
  team_names.each do |tn|
    next_user_id = unassigned_users.pop
    if next_user_id
      motto = get_lorem_ipsum((rand * 9.0) + 3)
      team = competition.teams.create :name=>tn, :motto=>motto
      team.team_memberships.create :is_leader=>true, :user_id=>next_user_id, :status=>1
      competition.team_size_min.times do |i|
        if team.members.count < competition.team_size_max
          next_user_id = unassigned_users.pop
          if next_user_id
            team.team_memberships.create :user_id=>next_user_id, :status=>1
            if team.members.count >= competition.team_size_min
              team.make_official
            end
          else
            puts "out of unassigned users in Promotion##{competition.promotion.id} / #{competition.promotion.subdomain}.  Generate some more users."
            break
          end
        end
      end
    else
      puts "out of unassigned users in Promotion##{competition.promotion.id} / #{competition.promotion.subdomain}.  Generate some more users."
      break
    end
  end
end

def fix_recipes
  puts "checking recipes..."
  user = ActiveRecord::Base.connection.select_all("select user() user").first['user'].split('@').first

  count = ActiveRecord::Base.connection.select_all("select count(1) cnt from central.apps where name = '#{user}'").first['cnt'].to_i

  if count.zero?
    ActiveRecord::Base.connection.execute("insert central.apps (name,title,is_active) values ('#{user}','#{APPLICATION_NAME}',1)")
    puts "added #{user} central app for recipes in #{APPLICATION_NAME}"
  end

  this_app_id = ActiveRecord::Base.connection.select_all("select id from central.apps where name = '#{user}'").first['id'].to_i

  recipe_ids = ActiveRecord::Base.connection.select_all("select id from central.recipes where is_active = 1 limit 300").collect{|row|row['id']}

  added = 0
  recipe_ids.each_with_index do |rid,i|
    recipe_count = ActiveRecord::Base.connection.select_all("select count(1) cnt from central.app_recipes where app_id = '#{this_app_id}' and sequence = #{i+1}").first['cnt'].to_i
    if recipe_count.zero?
      ActiveRecord::Base.connection.execute("insert central.app_recipes (app_id,recipe_id,sequence) values (#{this_app_id},'#{rid}',#{i+1})")
      added += 1
    end
  end
  puts "added #{added} recipes to the central app tied to #{user} for #{APPLICATION_NAME}"
end




# since we're dropping databases, we better make sure this only runs in dev...
if Rails.env.development?
  yaml = YAML::load File.open("config/database.yml").read
  yaml.symbolize_keys!
  config = yaml[:development]
  config.symbolize_keys!
  
  mysql_command = "mysql"
  mysql_command << " -h #{config[:host]} " if config[:host]
  mysql_command << " -u #{config[:username]} " if config[:username]
  mysql_command << " --password=\"#{config[:password]}\" " if config[:password]
  db = config[:database]

  puts "loading some data on #{config[:host] || 'localhost'}... this may take a few minutes"
  create_script = <<EOF 
   use #{db};
   source db/backups/fakenames.sql; 
EOF

  puts create_script
  `#{mysql_command} <<< "#{create_script}"`
end

Promotion.destroy_all
User.destroy_all

fix_recipes

create_www_promotion

create_logging_promotion
