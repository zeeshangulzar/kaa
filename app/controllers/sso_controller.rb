class SsoController < ApplicationController
  authorize :index, :public

  def index
    return HESResponder('SSL Required.', "DENIED") if Rails.env.production? && !request.ssl?
    if request.post?
      if validate_post
        handle_post
      else
        return HESResponder("Invalid SSO parameters.", "ERROR")
      end
    else
      handle_get
    end
  end
  
  private
  def validate_post  # make sure they posted what they were supposed to post
    @key = params[:key]
    @identifier = params[:identifier]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @email = params[:email]

    if @key.nil?
      # this might be an XML post
      return HESResponder('Incorrect post.', "ERROR")
      # TODO: implement this
    else
      # this is a HTTP form post
      if @identifier.nil?
        return HESResponder('Identifier missing.', "ERROR")
      else
        return true
      end
    end
  end

  def handle_post  # creation of SSO record
    # this is a HTTP form post
    info=DomainConfig.parse(request.host) # see config/initializers/domain_config.rb
    org = Organization.find(:first,:conditions=>{:wskey=>@key,'promotions.subdomain'=>info[:subdomain]},:include=>:promotions)

    unless org.nil?
      if org.is_sso_enabled
        #if org.flags[:auto_register_users] && @email.to_s.strip.empty?
        #  render :text=> 'Email is required.', :status => 400 and return
        #end

        # find all active promotions, sorted by launch_on;  then choose the one that launched before today, or the first of those, or the first promotion within the organization
        promos = org.promotions.find(:all,:conditions=>{:is_active=>true},:order=>:launch_on) 
        promo = promos.select{|p|p.launch_on <= Date.today}.first || promos.first || org.promotions.first

        if (!promo.flags[:is_verification_displayed]) || promo.eligibilities.find_by_identifier(@identifier)
          token = SecureRandom.hex(16) 
          sso = nil
          Sso.transaction do
            sso = Sso.create(:token => token, :promotion_id => promo.id, :identifier => @identifier, :first_name => @first_name, :last_name => @last_name, :email => @email)
          end
          #handle_extras(sso)  
          if !sso
            return HESResponder('Unable to create SSO record.', "ERROR")
          else
            new_url = construct_url(info[:host],request.port,"/sso?token=#{token}")
            # current sso clients are expecting a text response..
            response.headers["Content-Length"] = new_url.length.to_s
            render :text => new_url, :status => 200, :content_type => "text/html" and return
            #return HESResponder({:url => new_url}) 
          end
        else
          return HESResponder('Eligibility record not found', "DENIED")
        end
      else
        return HESResponder('SSO is disabled', "DENIED")
      end
    else
      return HESResponder('Incorrect key', "DENIED")
    end
  end

  def construct_url(host,port,path,new_subdomain=nil)
    h=new_subdomain ? DomainConfig.swap_subdomain(host,new_subdomain) : host
    "http#{'s' if port==443}://#{h}#{":#{port}" unless [80,443].include?(port)}#{path}"
  end

  def handle_get   # validation of SSO record
    reset_session

    token = params[:token]
    sso = Sso.find_by_token(token,:include=>:promotion)
    redirect_to '/sso/timeout' and return if (Time.now - sso.created_at > 10.seconds)
    redirect_to '/sso/timeout' and return if sso.used_at
    sso.update_attributes :used_at=>Time.now
    # uncomment when debug records are no longer needed (NEVER UNCOMMENT!  we are using SSO extras now)
    # sso.destroy
    user = sso.promotion.users.find(:first,:conditions=>{:sso_identifier => sso.identifier}) rescue nil
    session[:sso_identifier] = sso.identifier
    session[:sso_info] = {:first_name=>sso.first_name,:last_name=>sso.last_name,:email=>sso.email,:id=>sso.id}
    unless user.nil?
      log_user_in(user,sso)
    else
      send_to_register(sso)
    end
  end

  def handle_extras(sso)
    promo = sso.promotion
    if promo.sso_extras.size > 0
      # need to examine params for other values, and shove them into the sso record's UDF collection
      udfs = sso.build_udfs
      promo.sso_extras.each do |extra|
        cfn = extra.udf_def.cfn.to_sym
        udfs.send("#{cfn}=", params[extra.name])
      end
      udfs.save
      Rails.logger.warn "SSO transaction looked for extras.  Result saved as: #{udfs.inspect}"
    end
  end  
  
  # everything above here should be reused in apps without modification - gokp required some mods
  # everything below here may need to be customized per app

  def handle_automatic_registration(sso)
    user = sso.promotion.users.build(:sso_identifier=>sso.identifier)
    user.build_contact(:first_name => sso.first_name, :last_name => sso.last_name, :email => sso.email)
    sso.update_user_extras(user,true)
    User.transaction do 
      user.save!
      Stat.create_stats_for_trip(user.trip)
      user.add_notification("Welcome to <span class='#{Constant::AppNameClass}'>#{@promotion.program_name}</span>#{'!' unless @promotion.program_name.include?('!')} You will receive important notifications here.")

      add_team_memberships(user)
      update_friendship_requests(user)
        
      user.flags[:has_start_date] = true
      user.finish_creating_entries

      log_user_in(user)
    end
    HESAsync.deliver_welcome_email(:user => user, :promotion => user.promotion, :host => get_host)
  end

  def add_team_memberships(user)
    if user.promotion.current_competition && user.promotion.current_competition.during_enrollment?
      invite_email = user.contact.email.downcase
      unless session[:team_membership_id].nil?
        tm = TeamMembership.find_by_id(session[:team_membership_id])
        return if tm.nil?
        invite_email = tm.email.downcase
        tm.update_attributes(:user => user, :email => user.contact.email)
        session[:team_membership_id] = nil
      end
      
      user.promotion.current_competition.invites.find(:all, :conditions => {:email => invite_email}).each do |i|
        begin
          i.update_attributes(:user_id => user.id, :email => user.contact.email)
          user.add_notification("You're invited to <a href='/users/#{user.id}/team_memberships'>join #{i.team.name}</a>.", "team_invite_#{i.id}") if user.notifications.find_by_key("team_invite_#{i.id}").nil?
        rescue
        end
      end
    end
  end
  private :add_team_memberships

  def update_friendship_requests(user)
    invite_email = user.contact.email.downcase
    unless session[:friendship_id].nil?
      friendship = Friendship.find(session[:friendship_id])
      invite_email = friendship.email.downcase
      friendship.update_attributes(:friend_id => user.id, :email => user.contact.email)
      session[:friendship_id] = nil
    end
    
    Friendship.all(:include => :user, :conditions => ["email = :email AND users.promotion_id = :promotion_id", {:email => user.contact.email, :promotion_id => user.promotion.id}]).each do |f|
      begin
        unless f.user.nil? || f.user.contact.nil? #can happen if a user has been delete
          f.update_attributes(:friend_id => user.id, :email => user.contact.email)
          f.friend.add_notification("#{f.user.contact.full_name} has requested to be your <a href='/users/#{user.id}/#{Friendship::Label.pluralize.urlize}'>#{ Friendship::Label}</a>.", "friendship_#{f.id}")
        end
      rescue
      end
    end
  end

  # this is for existing users
  def log_user_in(user,sso)
    # NOTE: had to use set-cookie for basic, cookies[] url encoded the header and broke the app. wee!
    response['set-cookie'] = "basic=#{user.auth_basic_header}"
    cookies['sso_session_token'] = sso.session_token
    cookies['clear_local_storage'] = "true"
    headers['X-SSO-ACTION'] = 'log_user_in'
    redirect_to '/'
  end
  
  # this is for new users
  def send_to_register(sso)
    cookies.delete 'basic'
    cookies['sso_session_token'] = sso.session_token
    cookies['sso_info'] = {:first_name => sso.first_name, :last_name => sso.last_name, :email => sso.email}.to_json
    cookies['clear_local_storage'] = "true"
    headers['X-SSO-ACTION'] = 'register'
    redirect_to '/#/register'
  end
end
