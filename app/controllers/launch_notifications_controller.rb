class LaunchNotificationsController < ApplicationController
  authorize :create, :public

  # Create a user
  #
  # @url [POST] /users
  # @authorize Public
  # TODO: document me!
  def create
    return HESResponder("No email provided.", "ERROR") if params[:launch_notification].nil? || params[:launch_notification][:email].nil? || params[:launch_notification][:email].empty?
    params[:launch_notification][:subdomain] ||= @promotion.subdomain if @promotion
    params[:launch_notification][:subdomain] ||= request.host.split('.').first

    launch_notification = LaunchNotification.create(params[:launch_notification])

    return HESResponder(launch_notification)
  end
end
