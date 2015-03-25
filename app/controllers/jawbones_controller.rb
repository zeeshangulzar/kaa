class JawbonesController < ApplicationController
  authorize :authorize, :settings, :disconnect, :failed, :use_jawbone_data, :user
  authorize :post_authorize, :notify, :public

  def authorize
    devices_host = Rails.env.production? ? nil : "http://devices.dev" # change this in dev if necessary
    #session[:jawbone_user_id] = @current_user.id
    #unless params[:return_url].to_s.strip.empty?

   if @current_user.jawbone_user
      @current_user.jawbone_user.disconnect
      @current_user.update_column(:active_device, nil) if @current_user.active_device == 'JAWBONE'
      #@current_user.jawbone_user.destroy (MySQL error when deleting from view... have to do it manually)
      ActiveRecord::Base.connection.execute "delete from fbskeleton.jawbone_users where id = #{@current_user.jawbone_user.id}"
    end
   
      return_url = "#{request.host_with_port}/jawbones/post_authorize?auth_key=#{@current_user.auth_key}"
      redirect_url = HESJawbone.begin_authorization(@current_user, :return_url => return_url, :devices_host => devices_host)
      render :json => {:url=>redirect_url}
    #else
    #  render :json => {:url=>"missing return_url parameter"}, :status => 422
    #end
  end

  def settings
  end

  def post_authorize
    if params[:message].nil?
      #u = User.find(session[:jawbone_user_id])
      u = User.find_by_auth_key(params[:auth_key])
      HESSecurityMiddleware.set_current_user(u)
      HESJawbone.finalize_authorization(u)
      u.reload.jawbone_user.reload
      u.update_column :active_device, 'JAWBONE'

      notification = u.notifications.find_by_key('JAWBONE') || u.notifications.build(:key=>'JAWBONE')
      if u.profile.started_on >= u.promotion.current_date
        notification.update_attributes :title=> "Jawbone Connected", :message=>"Your UP tracker will sync with <i>Go KP</i> starting #{u.profile.started_on.strftime('%B %e')}."
      else
        # backlog data... 
        daysBack = (u.promotion.current_date - u.profile.started_on).to_i
        daysBack = [daysBack,u.promotion.backlog_days].min if u.promotion.backlog_days.to_i > 0
      
        # pull the jawbone data
        u.jawbone_user.pull_moves_since_last_sync(daysBack)
 
        # queue the data to be logged; but first set any notifications to 'new' so that the resque task will see and reprocess them
        User.connection.execute "update jawbone_notifications set status = '#{JawboneNotification::Status[:new]}' where jawbone_user_id = #{u.jawbone_user.id}"
        Resque.enqueue(JawboneNotificationJob, [u.jawbone_user.xid])

        notification.update_attributes :title=> "Jawbone Connected", :message=>"Your UP tracker will sync with <i>Go KP</i> shortly."
      end
      redirect_to Rails.env.production? 'http://#{u.promotion.subdomain}.healthyworkforce-gokp.org/#/settings' : 'http://www.go.dev:9000/#/settings'
    else
      redirect_to Rails.env.production? 'http://#{@current_user.promotion.subdomain}.healthyworkforce-gokp.org/#/settings' : 'http://www.go.dev:9000/#/settings'
    end
    #session[:jawbone_user_id] = nil
  end

  def disconnect 
    if @current_user.jawbone_user
      @current_user.jawbone_user.disconnect
      @current_user.update_column(:active_device,nil) if @current_user.active_device == 'JAWBONE'
      #@current_user.jawbone_user.destroy (MySQL error when deleting from view... have to do it manually)
      ActiveRecord::Base.connection.execute "delete from fbskeleton.jawbone_users where id = #{@current_user.jawbone_user.id}"
    end
    head :ok 
  end

  def failed
    redirect_to "/users/#{@current_user.id}/edit"
  end

  def refresh_week
    if master?
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
        mon = u.trip.profile.started_on + (params[:week].to_i * 7.0)
        sun = mon + 6
        jbu.pull_moves_in_range(mon,sun)
        (mon..sun).each do |day|
          if day <= @promotion.current_date
            entry = u.trip.entries.find_by_logged_on(day)
            jmd = JawboneMoveData.find(:first,:conditions=>{:jawbone_user_id=>jbu.id,:on_date=>day})
            if !jmd.nil?
              p = u.promotion
              JawboneLogger.log_entry(entry,p.single_day_exercise_limit,jbu,jmd,true)
            end
          end
        end
      end
    end
    u ||= @current_user
    redirect_to "/users/#{u.id}/edit#refresh_jawbone_data"
  end

  def notify                   

    Rails.logger.warn "JAWBONE NOTIFICATION!!!\n#{params.inspect}"

    user_xids = []
    begin
      events = params[:events]
      events.each do |event|
        begin
          if event[:type] == "move"
            jbu = JawboneUser.find(:first, :conditions => {:xid => event[:user_xid]}, :order => "created_at DESC")
            if jbu && jbu.user
              HESSecurityMiddleware.set_current_user(jbu.user) 
              jn = jbu.add_notification(event)
              user_xids << event[:user_xid]
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

    Resque.enqueue(JawboneNotificationJob, user_xids.uniq)

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
