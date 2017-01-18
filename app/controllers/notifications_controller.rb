# Controller for handling all notification requests
class NotificationsController < ApplicationController
  # Get the notificationable type and user before each request.
  before_filter :get_notificationable, :only => [:index, :keyed_notifications, :create, :destroy]

  authorize :index, :show, :update, :mark_as_seen, :mark_as_read, :user
  authorize :create, :get_past_notifications, :keyed_notifications, :coordinator
  authorize :destroy, :master

  # Extra authorize parameters
  def authorization_parameters
    @notification = Notification.find_by_id(params[:id])
    @notificationable = @notification ? @notification.notificationable : params[:notificationable_type].singularize.camelcase.constantize.find_by_id(params[:notificationable_id]) if params[:notificationable_type]
    [@notification, @notificationable]
  end

  # Get the notificationable type and user, or render an error.
  def get_notificationable
    @notificationable ||= params[:notificationable_type].singularize.camelcase.constantize.find(params[:notificationable_id]) if params[:notificationable_type] && params[:notificationable_id]
  end


  def get_past_notifications
    past_notifications = Notification.find_all_by_key_group_by_created_at(@promotion)
    return HESResponder(past_notifications)
  end

  def index
    notification_owner = @notificationable || @current_user
    notifications = params[:show_hidden].nil? ? notification_owner.notifications.includes(:from_user => [:profile, :location]).visible : notification_owner.notifications.includes(:from_user => [:profile, :location])
    return HESResponder(notifications)
  end

  def keyed_notifications
    notification_owner = @notificationable || @current_user
    notifications = Notification::find_all_group_by_key(notification_owner)
    data = []
    notifications.each{|notification|
      n = {
        :id           => notification.id,
        :total        => notification.total,
        :total_seen   => notification.total_seen,
        :total_read   => notification.total_read,
        :key          => notification.key,
        :title        => notification.title,
        :message      => notification.message,
        :created_at   => notification.created_at
      }
      data << n
    }
    return HESResponder(data)
  end

  def show
    notification ||= Notification.find(params[:id]) rescue nil
    return HESResponder("Notification", "NOT_FOUND") if !notification
    return HESResponder("You may not view this notification", "DENIED") if notification.user_id != @current_user.id && !@current_user.coordinator_or_above?
    return HESResponder(notification)
  end

  def create
    from_user = params[:notification][:from_user] != '0' ? @current_user : nil
    users = @promotion.users.select(:id)
    key = params[:key] ? params[:key] : "coordinator_#{@promotion.current_time.to_i}"
    notification = Notification.create_for_users(@promotion, params[:notification][:title], params[:notification][:message], from_user, key, users)
    $redis.publish("newCoordinatorNotification", {:notification => notification.attributes.to_json, :promotion_id => @promotion.id}.to_json)
    n = {
      :id           => notification.id,
      :total        => notification.total,
      :total_seen   => notification.total_seen,
      :total_read   => notification.total_read,
      :key          => notification.key,
      :title        => notification.title,
      :message      => notification.message,
      :created_at   => notification.created_at
    }
    return HESResponder([n])
  end

  def update
    updateable_attrs = ['hidden', 'seen', 'read']
    attrs = scrub(params[:notification], updateable_attrs)
    if params[:id]
      notification ||= @current_user.notifications.find(params[:id]) rescue nil
      return HESResponder("Notification", "NOT_FOUND") if !notification || notification.user_id != @current_user.id
      notification.update_attributes(attrs)
      return HESResponder(notification.errors.full_messages, "ERROR") if !notification.valid?
      return HESResponder(notification)
    elsif params[:ids]
      notifications = @current_user.notifications.where(:id => params[:ids])
      notifications.each do |notification|
        notification.update_attributes(attrs)
      end
      return HESResponder(notifications)
    else
      return HESResponder("Must pass an id or a group of ids", "ERROR")
    end
  end

  def destroy
    notification = @current_user.notifications.find(params[:id])
    Notification.delete_group(notification.notificationable, notification.created_at)
    return HESResponder(notification)
  end

  def mark_as_seen
    mark(:seen, params[:ids])
  end

  def mark_as_read
    mark(:read, params[:ids])
  end

  def mark(as, ids)
    if ids == 'all'
      Notification.transaction do
        @current_user.notifications.update_all(as => true)
      end
    else
      if ids.is_a?(Array)
        nids = ids
      elsif ids.is_a?(Integer) || (ids.is_a?(String) && ids.is_i?)
        nids = [ids]
      else
        return HESResponder("Bad id format.", "ERROR")
      end
      user_id = Notification.where(:id => nids).pluck(:user_id).uniq.first rescue nil
      if user_id.nil?
        return HESResponder("Some invalid notifications.", "ERROR")
      else
        if user_id != @current_user.id && !@current_user.master?
          return HESResponder("Not your notifications.", "DENIED")
        else
          Notification.transaction do
            Notification.find(nids).each{|n|
              n.update_attributes(:seen => true)
            }
          end
        end
      end
    end
    return HESResponder()
  end
  private :mark

end
