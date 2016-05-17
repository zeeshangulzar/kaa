namespace :devices do

  desc "Destroy all users in the 9 devices promotions and prepare them for testing according to the wiki article"
  task :make_promotions => :environment do
    subdomains = ['devices','buydeviceormanual','byodevice','byodeviceorbuy','byodeviceormanual','deviceormanualnooverride','fitbitsaleslimit','frozendevices','nodevices','forceandoverride']
    d1 = 14.days.ago
    dx = d1 + 28.days
    # map_id = Map.packages.first.id

    r=Reseller.find_by_name('Devices Testing')
    if r
      r.organizations.each do |o|
        o.promotions.each do |p|
          p.destroy
          puts "destroyed #{p.subdomain}"
        end
        o.destroy
        puts "destroyed organization #{o.name}"
      end
      r.destroy
      puts "destroyed reseller #{r.name}"
    end

    r=Reseller.create(:name=>'Devices Testing')

    o=r.organizations.find_by_name('Devices Testing')
    o.destroy if o
    o=r.organizations.create(:name=>'Devices Testing')


    subdomains.each do |subdomain|
      p=Promotion.find_by_subdomain(subdomain)
      if p
        p.users.each{|u|u.destroy}
        p.destroy
        puts "destroyed #{subdomain}"
      end

      o.promotions.create(
        :name=>subdomain,
        :program_name=>subdomain,
        :subdomain=>subdomain,
        :launch_on=>d1,
        :starts_on=>d1,
        :registration_starts_on=>d1,
        :registration_ends_on=>dx,
        :late_registration_ends_on=>dx,
        :is_registration_frozen=>false,
        :is_active=>true,
        :program_length=>28)
        # :potential_number_of_registrants=>5,
        # :comments=>'testing')
      puts "created #{subdomain}"
    end


    # for more information on what's below, see http://wiki.hesonline.net/doku.php?id=feature:checklists:devices

    p=Promotion.find_by_subdomain('devices')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=true
    p.save
 
    p=Promotion.find_by_subdomain('buydeviceormanual')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=true
    p.save

    p=Promotion.find_by_subdomain('byodevice')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=false
    p.flags[:disable_manual_logging]=true
    p.save
  
    p=Promotion.find_by_subdomain('byodeviceorbuy')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=false
    p.flags[:disable_manual_logging]=true
    p.save
  
    p=Promotion.find_by_subdomain('byodeviceormanual')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=true
    p.save
  
    p=Promotion.find_by_subdomain('deviceormanualnooverride')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=false
    p.save

    p=Promotion.find_by_subdomain('fitbitsaleslimit')
    p.flags[:is_fitbit_enabled]=true
    p.save

    p=Promotion.find_by_subdomain('forceandoverride')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=true
    p.flags[:disable_manual_logging]=true
    p.save

    p=Promotion.find_by_subdomain('frozendevices')
    p.flags[:is_fitbit_enabled]=true
    p.flags[:is_jawbone_enabled]=true
    # p.flags[:enable_garmin]=true
    p.flags[:is_manual_override_enabled]=true
    p.save
   end  
  
end
