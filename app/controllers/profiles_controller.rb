class ProfilesController < ApplicationController
  authorize :show, :update, :user

  def index
    # i don't think this should be a thing
  end

  # Get a profile
  #
  # @url [GET] /users/1/profile
  # @param [Integer] id The id of the user and grab their profile
  # @return [Profile] Profile that matches the user's id
  #
  # [URL] /users/:id/profile [GET]
  #  [200 OK] Successfully retrieved Profile
  def show
    return HESResponder(@target_user.profile)
  end

  def create
    # this prolly shouldn't exist either, you can only create a profile in conjunction with a user
  end
  
  def update
    if @target_user.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit others' profiles.", "DENINED")
    end
    Profile.transaction do
      @target_user.profile.update_attributes(params[:profile])
    end
    if @target_user.profile.valid?
      return HESResponder(@target_user.profile)
    elsif @target_user.profile.errors
      return HESResponder(@target_user.profile.errors.full_messages, "ERROR")
    else
      return HESResponder("Error updating profile.", "ERROR")
    end
  end
  
  def destroy
    # you shouldn't be able to delete a profile separate from user
  end

end
