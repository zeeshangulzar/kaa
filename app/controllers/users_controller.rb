class UsersController < ApplicationController
  authorize :create, :validate, :public
  authorize :search, :show, :user
  authorize :update, :user
  authorize :index, :coordinator
  authorize :destroy, :master
  authorize :authenticate, :public

  def index
    return HESResponder(@promotion.users.find(:all,:include=>:profile))
  end

  def authenticate
    info = DomainConfig.parse(request.host)
    if @promotion
      user = @promotion.users.find_by_altid(params[:email]) rescue nil
      unless params[:email].nil? || params[:email].empty?
        user ||= @promotion.users.find_by_email(params[:email]) rescue nil
      end
      user = user && user.password == params[:password] ? user : nil
    elsif @promotion.nil? && info[:subdomain] == 'api' && !params[:email].nil? && !params[:email].empty?
      users = User.find(:all,
                :conditions => 
                  [
                    "altid = ? or email = ?",
                    params[:email], params[:email]
                  ],
                :order => "users.created_at DESC")
      user = users.detect{|u| u.password == params[:password]}
    end
    HESSecurityMiddleware.set_current_user(user)
    if user

      user.last_login = user.promotion.current_time
      user.save!

      json = user.as_json
      json[:auth_basic_header] = user.auth_basic_header
      render :json => json and return
    else
      return HESResponder("NUID or password is incorrect.", 401)
    end
  end

  # Get a user
  #
  # @url [GET] /users/1
  # @param [Integer] id The id of the user
  # @return [User] User that matches the id
  #
  # [URL] /users/:id [GET]
  #  [200 OK] Successfully retrieved User
  def show
    if @target_user.id == @current_user.id || @target_user.friends.include?(@current_user) || @current_user.master?
      @target_user.stats = @target_user.stats
      @target_user.recent_activities = @target_user.recent_activities
      if @target_user.id == @current_user.id || @current_user.sub_promotion_coordinator_or_above?
        @target_user.completed_evaluation_definition_ids = @target_user.completed_evaluation_definition_ids
      end
    end
    return HESResponder(@target_user)
  end



  # Create a user
  #
  # @url [POST] /users
  # @authorize Public
  # TODO: document me!
  def create
    return HESResponder("No user provided.", "ERROR") if params[:user].empty?
    demographic = false
    if !params[:user][:profile].nil?
      if !params[:user][:profile][:age].nil? || !params[:user][:profile][:gender].nil? || !params[:user][:profile][:ethnicity].nil?
        demographic = Demographic.new()
        demographic.age = params[:user][:profile].delete(:age) if !params[:user][:profile][:age].nil?
        demographic.gender = params[:user][:profile].delete(:gender) if !params[:user][:profile][:gender].nil?
        demographic.ethnicity = params[:user][:profile].delete(:ethnicity) if !params[:user][:profile][:ethnicity].nil?
      end
      params[:user][:profile] = Profile.new(params[:user][:profile])
    end

    if params[:user][:evaluation] && params[:user][:evaluation][:evaluation_definition_id]
      ed = EvaluationDefinition.find(params[:user][:evaluation][:evaluation_definition_id]) rescue nil
      if ed && ed.promotion_id == @promotion.id
        eval_params = params[:user][:evaluation]
        params[:user].delete(:evaluation)
      else
        return HESResponder("Invalid evaluation definition.", "ERROR")
      end
    else
      eval_params = nil
    end

    user = @promotion.users.new(params[:user])
    User.transaction do
      if !user.valid?
        return HESResponder(user.errors.full_messages, "ERROR")
      else
        user.save!
        if eval_params
          eval_params[:user_id] = user.id
          eval = ed.evaluations.build(eval_params)
          if eval.valid?
            eval.save!
          end
        end
        if demographic
          demographic.user_id = user.id
          demographic.save!
        end
      end
    end
    user.welcome_notification
    return HESResponder(user)
  end
  
  def update
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit this user.", "DENIED")
    else
      User.transaction do
        profile_data = !params[:user][:profile].nil? ? params[:user].delete(:profile) : []

        if params[:flags]
          @target_user.flags.keys.each{|flag|
            @target_user.flags[flag] = params[:flags][flag] if !params[:flags][flag].nil?
          }
        end

        profile_data.delete :id
        profile_data.delete :url
        profile_data.delete :backlog_date

        @target_user.update_attributes(params[:user])
        @target_user.profile.update_attributes(profile_data) if !profile_data.empty?
      end
      if !@target_user.valid?
        errors = !@target_user.profile.errors.empty? ? @target_user.profile.errors : @target_user.errors # the order here is important. profile will have specific errors.
        return HESResponder(errors.full_messages, "ERROR")
      else
        return HESResponder(@target_user)
      end
    end
  end
  
  def destroy
    if @current_user.master? && @current_user.id != @target_user.id
      User.transaction do
        @target_user.destroy
      end
      return HESResponder(@target_user)
    end
  end

  def search
    search_string = params[:search_string].nil? ? params[:query] : params[:search_string]
    if search_string.nil? || search_string.blank?
      return HESResponder([])
    else
      search_string = search_string.strip
    end
    if params[:unassociated].nil?
      conditions = ["users.email like ? or profiles.first_name like ? or profiles.last_name like ?",search_string, search_string, search_string]
      p = (@current_user.master? && params[:promotion_id] && Promotion.exists?(params[:promotion_id])) ? Promotion.find(params[:promotion_id]) : @promotion
      users = p.users.find(:all,:include=>:profile,:conditions=>conditions)
    else
      limit = !params[:limit].nil? ? params[:limit].to_i : 50
      users = @current_user.unassociated_search(search_string, limit)
    end
    return HESResponder(users, "OK", limit)
  end


  # this just checks for uniqueness at the moment
  def validate
    fs = ['email','username', 'altid']
    f = params[:field]
    if !fs.include?(f)
      return HESResponder("Can't check this field.", "ERROR")
    end
    f = f.to_sym
    v = params[:value]
    if @promotion.users.where(f=>v).count > 0
      return HESResponder(f.to_s.titleize + " is not unique within promotion.", "ERROR")
    else
      return HESResponder()
    end
  end

  def stats
    user = (@target_user.id != @current_user.id) ? @target_user : @current_user
    year = !params[:year].nil? && params[:year].is_i? ? params[:year] : @promotion.current_date.year
    return HESResponder(user.stats(year))
  end

  def forgot
    user = User.find(:first, :conditions => ["email = ?", params[:email]])
    unless user.nil?
      GoMailer.forgot_password(user, get_host).deliver
    end
    return HESResponder()
  end

  # Reset the user password to the new password
  # Check is done to make sure the password is allowed to be changed for the user
  def password_reset
    password_changed = false;
    if allow_password_reset()
      unless params[:password].to_s.strip.empty?
        @password_reset_user.password = params[:password]
        @password_reset_user.save!
        @password_reset_user.initialize_aes_iv_and_key
        @password_reset_user.save!
        GoMailer.password_reset(@password_reset_user, get_host).deliver
        password_changed=true
      end
    end

    return HESResponder({:password_changed => password_changed})
  end

  #Verify the password reset is allowed
  def verify_password_reset
    return HESResponder({:allow => allow_password_reset()})
  end

  def allow_password_reset()
    # link in email is a big string separated by ~ and it is encrypted *with the app's AES key* and base-64 encoded
    # example: 983~BmpnaBfzyLgfVltNMyPvVG4SFB2%0AcKuwHwkP8sKk%2BqDt2DYvWE33uT6tr
    # element 0 is the user's ID
    # element 1 is a big string separated by ~ and it is encrypted *with the user's AES key* and base-64 encoded
    # element 1,0 is random hex for padding
    # element 1,1 is the user's id
    # element 1,2 the date/time the link was created
    #
    # the link must be less than 60 minutes old (i.e. element 1,2 is a timestamp that must not be older than 60 minutes)
    allow_password_reset=false
    if params[:id]
      key = params[:id]
      decoded_key = PerModelEncryption.url_base64_decode(key)
      string = Encryption.decrypt(decoded_key) rescue nil
      if string
        user_id,encrypted_information = string.split('~')
        if user_id && encrypted_information
          @password_reset_user = User.find(user_id)
          if @password_reset_user
            decrypted_information = @password_reset_user.aes_decrypt(PerModelEncryption.url_base64_decode(encrypted_information))
            pieces = decrypted_information.split('~')
            if pieces.size==4 && @password_reset_user.id == pieces[1].to_i
              link_timestamp = Time.at(pieces[2].to_i).utc
              age = Time.now.utc - link_timestamp
              if age < 3600
                allow_password_reset = true
              end
            end
          end
        end
      end
    end
    return allow_password_reset
  end

end
