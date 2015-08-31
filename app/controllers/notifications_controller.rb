# Controller for handling all notification requests
class NotificationsController < ApplicationController
  respond_to :json

  # Get the notificationable type and user before each request.
  before_filter :get_notificationable, :only => [:index, :keyed_notifications, :create, :destroy]

  authorize :index, :show, :update, :user
  authorize :create, :destroy, :get_past_notifications, :keyed_notifications, :coordinator

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
    notifications = params[:show_hidden].nil? ? notification_owner.notifications.visible : notification_owner.notifications
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
        :total_viewed => notification.total_viewed,
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
      :total_viewed => notification.total_viewed,
      :key          => notification.key,
      :title        => notification.title,
      :message      => notification.message,
      :created_at   => notification.created_at
    }
    return HESResponder([n])
  end

  def update
    updateable_attrs = ['hidden', 'viewed']
    attrs = scrub(params[:notification], updateable_attrs)
    # TODO: only allow recipient to update maybe??

    if params[:id]
      notification ||= Notification.find(params[:id]) rescue nil
      return HESResponder("Notification", "NOT_FOUND") if !notification
      notification.update_attributes(attrs)
      return HESResponder(notification.errors.full_messages, "ERROR") if !notification.valid?
      return HESResponder(notification)
    elsif params[:ids]
      notifications = Notification.where(:id => params[:ids])
      notifications.each do |notification|
        notification.update_attributes(attrs)
      end
      return HESResponder(notifications)
    else
      return HESResponder("Must pass an id or a group of ids", "ERROR")
    end
  end

  def destroy
    notification = Notification.find(params[:id])
    Notification.delete_group(notification.notificationable, notification.created_at)
    return HESResponder(notification)
  end
end
