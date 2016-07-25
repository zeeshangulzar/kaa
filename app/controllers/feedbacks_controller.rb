# Adds ability to create feedback through ActiveResource in application
class FeedbacksController < ApplicationController
  
  authorize :create, :public

  # Creates feedback from a user
  #
  # @example
  #  #POST /feedbacks
  #  {
  #    name: "Ryan Norman", 
  #    email: "ryann@hesonline.com", 
  #    feedback: "Best website I've ever used!",
  #    request_url: "http://test.passport.com",
  #    session_data: "Gobblygook from the request object in yaml format"
  #  }
  # @return [Feedback] that was just created
  #
  # [URL] /feedbacks [POST]
  #  [201 CREATED] Successfully created Survey object
  #   # Example response
  #   {
  #    "name": "Ryan Norman", 
  #    "email": "ryann@hesonline.com", 
  #    "feedback": "Best website I've ever used!",
  #    "request_url": "http://test.passport.com",
  #    "session_data": "Gobblygook from the request object in yaml format"
  #   }
  def create
    @feedback = Feedback.create({
      :email => params[:email] || @current_user.email,
      :name => params[:name] || @current_user.profile.full_name,
      :request_url => params[:request_url],
      :feedback => params[:feedback],
      :browser => params[:browser] || request.env['HTTP_USER_AGENT'],
      :os => params[:os] || request.env['HTTP_USER_AGENT'],
      :session_data => params[:session_data] || @current_user.to_json})
    return HESResponder(@feedback)
  end

  def feedback_url(feedback)
    return "/feedbacks/#{feedback.email}"
  end
end
