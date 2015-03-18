class FitbitsController < ApplicationController
  authorize :begin, :disconnect, :get_daily_summaries, :use_fitbit_data, :user
  authorize :post_authorize, :notify, :public

  # Begin the Fitbit OAuth connection process, and return a fitbit.com URL
  #
  # @url [POST] /fitbit/begin
  # @authorize User
  # @return [Obj] JSON object representing URL
  #
  # [URL] /fitbit/begin [POST]
  # @param [String] return_url The URL to redirect the browser to after success or failure 
  #  [200 OK] Success
  #   # Example response
  #    {:url=>"http://fitbit.com?token=abcdefg"}
  #  [422 Unprocessable Entity] Failure
  #   # Example response
  #    {:error=>"missing return_url parameter"}
  def begin
    unless params[:return_url].to_s.strip.empty?
      redirect_url = HESFitbit.begin_authorization(@current_user,:return_url=>params[:return_url])
      render :json => {:url=>redirect_url}
    else
      render :json => {:url=>"missing return_url parameter"}, :status => 422
    end
  end

  # Complete the Fitbit OAuth connection process, and redirect the user to a URL within this application
  # Clients should never use this URL.  This is the callback URL used by fitbit.com in the Fitbit OAuth connection process.
  #
  # @url [GET] /fitbit/post_authorize
  # @authorize public
  # @return 302 and URL  (a redirect)
  # 
  # [URL] /fitbit/post_authorize [GET]
  #  [302 Found]
  #   # Example response
  #   Location: http://example.com#/fitbit/success
  def post_authorize
    oauth_token = FitbitOauthToken.find_by_token(params[:oauth_token])
    if oauth_token
      user = oauth_token.user
      client = user.get_fitbit_client 
      access_token = client.authorize(oauth_token.token,oauth_token.secret,{:oauth_verifier=>params[:oauth_verifier]})
      User.transaction do
        oauth_token.update_attributes :token => access_token.token, :secret => access_token.secret
        user.retrieve_fitbit_user
        user.reload
        user.fitbit_user.subscribe_to_notifications
        user.fitbit_user.request_activity_through_today(false)
        notification = user.notifications.find_by_key('FITBIT') || user.notifications.build(:key=>'FITBIT')
        
        if user.profile.started_on >= user.promotion.current_date
          notification.update_attributes :title => "Fitbit Connected", :message=>"Your Fitbit data will sync with Go KP starting #{user.profile.started_on.strftime('%B %e')}."
        else
          notification.update_attributes :title => "Fitbit Connected", :message=>"Your Fitbit data will sync with Go KP shortly."
        end
        
        user.update_column :active_device, 'FITBIT'
      end
      extra_data = oauth_token.parse_extra_data
      redirect_to extra_data[:return_url]
    else
      render :text=>"Error: Fitbit OAuth failure"
    end
  end

  # Disconnect the user from Fitbit, end the subscription, and delete the fitbit_user record 
  #
  # @url [POST] /fitbit/disconnect
  # @authorize User
  #
  # [URL] /fitbit/begin [POST]
  #  [200 OK] Success
  def disconnect
    if @current_user.fitbit_user
      @current_user.fitbit_user.unsubscribe_from_notifications
      #@current_user.fitbit_user.destroy (MySQL error when deleting from view... have to do it manually)
      ActiveRecord::Base.connection.execute "delete from fbskeleton.fitbit_users where id = #{@current_user.fitbit_user.id}"
    end

    # set it to nil if it is FITBIT
    @current_user.update_column(:active_device,nil) if @current_user.active_device == 'FITBIT'
    
    head :ok 
  end

  # Disconnect the user from Fitbit, end the subscription, and delete the fitbit_user record 
  #
  # @url [POST] /fitbit/refresh_week
  # @param [String] user_id The user you would like to refresh
  # @param [String] fitbit_user_id The fitbit_user you would like to refresh
  # @param [String] encoded_id The fitbit_user you would like to refresh (to be found by their Fitbit encoded id).
  # @param [Integer] week The week number that you would like to refresh
  # @authorize User
  #
  # [URL] /fitbit/begin [POST]
  #   # Example response
  #   [200 OK] Success
  # [URL] /fitbit/begin [POST]
  #   [422 Unprocessable Entity] Failure
  #   # Example response
  #   {:error=>"user_id, fitbit_user_id, or encoded_id must be specified"}
  def refresh_week
      if params[:week].to_s.strip.empty?
        render :json => {:url=>"week must be specified"}, :status => 422 and return
      end

      if params[:user_id]
        uid = params[:user_id]
        u = User.find(uid)
        fbu = u.fitbit_user
      elsif params[:fitbit_user_id]
        fbu = FitbitUser.find(params[:fitbit_user_id])
        u = fbu.user if fbu
      elsif params[:encoded_id]
        fbu = FitbitUser.find_by_encoded_id(params[:encoded_id])
        u = fbu.user if fbu
      else
        render :json => {:url=>"user_id, fitbit_user_id, or encoded_id must be specified"}, :status => 422 and return
      end
 
      if fbu && u
        mon = u.profile.started_on + (params[:week].to_i * 7.0)
        sun = mon + 6
        client = u.get_fitbit_client
        oauth_token = u.fitbit_oauth_token
        (mon..sun).each do |day|
          if day <= u.promotion.current_date
            fbu.retrieve_activities_on_date day,client,oauth_token
            fbu.notifications.create :collection_type=>'activities',:date=>day,:owner_id=>fbu.encoded_id,:owner_type=>'user',:status=>FitbitNotification::Status[:processed]
          end
        end
        head :ok
      else
        render :json => {:url=>"User not found"}, :status => 422 and return
      end
  end

  def get_daily_summaries
    date = Date.parse(params[:current_date])
    chart_type = params[:chart_type]

    case chart_type
    when "week"
      first_day = date.beginning_of_week
      last_day = date.end_of_week
    when "month"
      first_day = date.beginning_of_month
      last_day = date.end_of_month
    end

    monthly_summary = @current_user.fitbit_user.daily_summaries.find(:all, :conditions => ["reported_on between ? and ?", first_day, last_day])

    # Fill in any missing days.
    complete_summary = []
    days = monthly_summary.collect(&:reported_on)
    
    (first_day..last_day).each do |day|
      if days.include?(day)
        existing_day = monthly_summary.select{|mt| mt.reported_on == day}.first
        blank_day = {}
        
        blank_day["reported_on"] = existing_day.reported_on
        blank_day["steps"] = existing_day.steps
        blank_day["calories_out"] = existing_day.calories_out
        blank_day["very_active_minutes"] = existing_day.very_active_minutes
        
        complete_summary << blank_day
      else
        blank_day = {}
        
        blank_day["reported_on"] = day
        blank_day["steps"] = 0
        blank_day["calories_out"] = 0
        blank_day["very_active_minutes"] = 0
        
        complete_summary << blank_day
      end
    end

    respond_to do |format|
      format.json {render :json => complete_summary}
    end
  end

  # Revert back to using Fitbit data instead of logging manually.
  def use_fitbit_data
    e = Entry.find(params[:entry_id])

    # @current_user.fitbit_user.retrieve_activities_on_date(e.recorded_on)
    fds = FitbitUserDailySummary.find(:first, :conditions => {:fitbit_user_id => @current_user.fitbit_user.id, :reported_on => e.recorded_on})

    e.manually_recorded = false
    e.exercise_steps = fds.steps
    e.save

    $redis.publish('fitbitEntrySaved', e.to_json)

    respond_to do |format|
      format.json {render :json => e}
    end
  end

  def notify
    Rails.logger.warn "FITBIT NOTIFICATION!!!\n#{params.inspect}"

    begin
      Resque.enqueue(FitbitNotificationJob, params[:_json])
    rescue => ex
      Rails.logger.warn "FITBIT NOTIFICATION FAILED!!!\n#{params.inspect}\n#{ex.backtrace.join("\n")}: #{ex.message} (#{ex.class})"
    end

    head :no_content
  end

end
