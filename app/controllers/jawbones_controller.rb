class JawbonesController < ApplicationController
  authorize :authorize, :settings, :disconnect, :failed, :use_jawbone_data, :user
  authorize :post_authorize, :notify, :public

  def authorize
    devices_host = IS_STAGING ? "http://devices.staging.hesapps.com" : Rails.env.development? ? 'http://localhost:3001' : nil
    redirect_to HESJawbone.begin_authorization(@user, :return_url => "#{request.host_with_port}/jawbone/post_authorize", :devices_host => devices_host)
  end

  def settings
  end

  def post_authorize
    if params[:message].nil?
      u = User.find_by_auth_key(params[:auth_key])
      HESSecurityMiddleware.set_current_user(u)
      HESJawbone.finalize_authorization(u)
      u.reload.jawbone_user.reload
      u.update_column :active_device, 'JAWBONE'

      notification = u.notifications.find_by_key('JAWBONE') || u.notifications.build(:key=>'JAWBONE')
      if u.profile.started_on >= u.promotion.current_date
        notification.update_attributes :title=> "Jawbone Connected", :message=>"Your UP tracker will sync with #{Constant::AppName} starting #{u.profile.started_on.strftime('%B %e')}."
      else
        # backlog data... 
        daysBack = (u.promotion.current_date - u.profile.started_on).to_i
        daysBack = [daysBack,u.promotion.backlog_days].min if u.promotion.backlog_days.to_i > 0
      
        # pull the jawbone data
        u.jawbone_user.pull_moves_since_last_sync(daysBack)
 
        # queue the data to be logged; but first set any notifications to 'new' so that the resque task will see and reprocess them
        User.connection.execute "update jawbone_notifications set status = '#{JawboneNotification::Status[:new]}' where jawbone_user_id = #{u.jawbone_user.id}"
        hash = {u.jawbone_user.xid => {:range=>u.started_on..Date.tomorrow}}
        Resque.enqueue(JawboneNotificationJob, hash)

        notification.update_attributes :title=> "Jawbone Connected", :message=>"Your Jawbone tracker will sync with #{Constant::AppName} shortly."
      end

      redirect_to = Rails.env.production? ? "https://#{u.promotion.subdomain}.healthfortheholidays.com/#/connection_successful" : "http://#{u.promotion.subdomain}.h4h-api.dev:9000/#/connection_successful"
    else

      # TODO: Is this right?
      redirect_to = Rails.env.production? ? "https://#{u.promotion.subdomain}.healthfortheholidays.com/#/connection_successful" : "http://#{u.promotion.subdomain}.h4h-api.dev:9000/#/connection_successful"
    end
    #session[:jawbone_user_id] = nil
  end

  def disconnect 
    # if @current_user.jawbone_user
      @current_user.jawbone_user.disconnect
      @current_user.update_column(:active_device,nil) if @current_user.active_device == 'JAWBONE'
      #@current_user.jawbone_user.destroy (MySQL error when deleting from view... have to do it manually)
      ActiveRecord::Base.connection.execute "delete from fbskeleton.jawbone_users where id = #{@current_user.jawbone_user.id}"
    # end
    head :ok 
  end

  def failed
    redirect_to "/users/#{@current_user.id}/edit"
  end

  def refresh_week
    if @current_user.master?
      Rails.logger.warn("REFRESH_WEEK : #{params.inspect}")
      require 'jawbone_logger'
      if params[:user_id]
        uid = params[:user_id]
        u = User.find(uid)
        jbu = u.jawbone_user
      elsif params[:jawbone_user_id]
        jbu = JawboneUser.find(params[:jawbone_user_id])
        u = jbu.user if jbu
      elsif params[:xid]
        jbu = JawboneUser.find_by_xid(params[:xid])
        u = jbu.user if jbu
      end
 
      if jbu && u && params[:week]
        mon = u.profile.started_on + (params[:week].to_i * 7.0)
        sun = mon + 6
        jbu.pull_moves_in_range(mon,sun)
        (mon..sun).each do |day|
          if day <= @promotion.current_date
            entry = u.entries.find_by_recorded_on(day)
            jmd = JawboneMoveData.find(:first,:conditions=>{:jawbone_user_id=>jbu.id,:on_date=>day})
            if !jmd.nil?
              p = u.promotion
              JawboneLogger.log_entry(jmd.date, jbu, jmd, true)
            end
          end
        end
      end

      head :ok
    end
  end

  def notify
    Rails.logger.warn "JAWBONE NOTIFICATION!!!\n#{params.inspect}"

    hash = {}
    begin
      events = params[:events]
      events.each do |event|
        begin
          if event[:type] == "move"
            jbu = JawboneUser.find(:first, :conditions => {:xid => event[:user_xid]}, :order => "created_at DESC")
            if jbu && jbu.user
              HESSecurityMiddleware.set_current_user(jbu.user) 
              jn = jbu.add_notification(event)
              hash[event[:user_xid]] ||= {:xids=>[]}
              hash[event[:user_xid]][:xids] << event[:event_xid]
            else
              Rails.logger.warn "Exception: no user matches: #{event.inspect}"
            end
          end
        rescue Exception => ex
          Rails.logger.warn "Exception <#{ex.class}>: #{ex.message}\n#{ex.backtrace.join("\n")}"
        end
      end
    rescue Exception => ex
      Rails.logger.warn "Exception <#{ex.class}>: #{ex.message}\n#{ex.backtrace.join("\n")}"
    end

    Resque.enqueue(JawboneNotificationJob, hash)

    head :ok
  end

  def use_jawbone_data
    e = Entry.find(params[:entry_id])

    jmd = JawboneMoveData.find(:all, :conditions => {:jawbone_user_id => @current_user.jawbone_user.id, :on_date => e.recorded_on})

    if jmd.count > 0
      e.manually_recorded = false
      e.exercise_steps = jmd.sum(&:steps)
      e.save

      $redis.publish('jawboneEntrySaved', e.to_json)

      render :json => e
    else
      render :json => {:url=>"User not found"}, :status => 422 and return
    end
  end
end
