# Controller for handling all notification requests
class NotificationsController < ApplicationController
	respond_to :json

	# Get the notificationable type and user before each request.
	before_filter :get_notificationable, :only => [:index, :create, :destroy]

	authorize :index, :show, :update, :user
	authorize :create, :destroy, :get_past_notifications, :coordinator

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

	# Gets a list of poast notifications create for a promotion's coordinator.
	# 
	# @url [GET] /notifications/get_past_notifications
	# @authorize Coordinator
	# @return [Array<Notification>] Array of notifications
	#
	# [URL] /notifications/get_past_notifications [GET]
	#  [200 OK] Successfully retrieved Notification Array object
	#   # Example response
	#    [{
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }]
	def get_past_notifications
		@past_notifications = Notification.find_all_by_key_group_by_created_at(@promotion)
		return HESResponder(@past_notifications)
	end

	# Gets a list of notifications for a user.
	# 
	# @url [GET] /notifications
  	# @url [GET] /notifications?show_hidden=true
	# @authorize User
	# @param [Boolean] show_hidden Whether or not to show hidden notifications
	# @return [Array<Notification>] Array of notifications
	#
	# [URL] /notifications [GET]
	#  [200 OK] Successfully retrieved Notification Array object
	#   # Example response
	#    [{
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }]
	def index
		notification_owner = @notificationable || @current_user
		@notifications = params[:show_hidden].nil? ? notification_owner.notifications.visible : notification_owner.notifications
		return HESResponder(@notifications)
	end

	# Gets a single notification for a user.
	#
	# @url [GET] /notifications/1
	# @authorize User
	# @param [Integer] id The id of the notification
	# @return [Notification] Notification that matches the id
	#
	# [URL] /notifications/:id [GET]
	#  [200 OK] Successfully retrieved Notification object
	#   # Example response
	#    {
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }
	def show
		@notification ||= Notification.find(params[:id]) rescue nil
    return HESResponder("Notification", "NOT_FOUND") if !@notification
    return HESResponder("You may not view this notification", "DENIED") if @notification.user_id != @current_user.id && !@current_user.master?
		return HESResponder(@notification)
	end

	# Creates a single notification for a user or many users in a promotion.
	#
	# @url [POST] /notifications
	# @authorize Coordinator
	# @param [String] title The title of the notification
	# @param [String] message The message of the notification
	# @param [Integer] from_user The from user id that will show who sent notification to user
	# @param [String] users The key that is used for sending out mass notifications
	# @return [Notification] Notification that matches the id
	#
	# [URL] /notifications [POST]
	#  [200 OK] Successfully created Notification object
	#   # Example response
	#    {
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }
	def create
		from_user = params[:notification][:from_user] != '0' ? @current_user : nil

		users = @promotion.users

		@notification = Notification.create_for_users(@promotion, params[:notification][:title], params[:notification][:message], from_user, params[:users], users)

		$redis.publish("newCoordinatorNotification", {:notification => @notification.as_json, :promotion_id => @promotion.id}.to_json)

		return HESResponder(@notification)
	end

  	# Updates a one or many notifications for a user
	#
	# @url [PUT] /notifications/:id
  	# @url [PUT] /notifications?ids[]=1&ids[]=2&ids[]=3&ids[]=4
	# @authorize User Owner of notification can mark notification(s) as viewed and hidden
	# @authorize Coordinator
	# @param [Integer] id The id of the notification
	# @param [Array<Integer>] ids An Array of ids to update
	# @param [String] title The title of the notification
	# @param [String] message The message of the notification
	# @param [Integer] from_user The from user id that will show who sent notification to user
	# @param [String] users The key that is used for sending out mass notifications
	# @return [Notification] Notification that matches the id
	#
	# [URL] /notifications/:id [PUT]
	#  [200 OK] Successfully created Notification object
	#   # Example response
	#    {
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }
	def update
		if params[:id]
			@notification ||= Notification.find(params[:id])
			@notification.update_attributes(params[:notification])
			return HESResponder(@notification)
		elsif params[:ids]
			@notifications = Notification.where(:id => params[:ids])
			@notifications.each do |notification|
				notification.update_attributes(params[:notification])
			end
		  	#respond_with @notifications, :location => "/notifications?ids=#{@notifications.collect(&:id).join(',')}"
        return HESResponder(@notifications)
		else
		  	return HESResponder("Must pass an id or a group of ids", "ERROR")
		end
	end

	# Destroys a group of notifications
	#
	# @url [DELETE] /notifications/1
	# @authorize Coordinator
	# @param [Integer] id The id of the notification
	# @param [Integer] notificationable_id The notificationable id of the model that owns the notification
	# @param [Integer] notificationable_type The notificationable type of the model that owns the notification
	# @return [Notification] Notification that was deleted
	#
	# [URL] /:notificationable_type/:notificationable_id/notifications/:id [DELETE]
	#  [200 OK] Successfully deleted Notification object
	#   # Example response
	#    {
	#      "id": 1,
	#      "user_id": 1,
	#      "from_user_id": 2,
	#      "title": "Test Title",
	# 	   "message": "This is a test notification",
	#      "viewed": false,
  	#      "hidden": false,
  	#      "key": "Test",
  	#      "notificationable_id": 1,
  	#      "notificationable_type": "Notification",
	#      "notificationable": {...},
	#      "user": {...},
	#      "created_at": "2014-03-07T14:33:09-05:00",
	#      "updated_at": "2014-03-07T14:33:09-05:00",
	#      "url": "http://api.hesapps.com/notifications/1"
	#    }
	def destroy
		@notification = Notification.find(params[:id])
		Notification.delete_group(@notification.notificationable, @notification.created_at)
		return HESResponder(@notification)
	end
end
