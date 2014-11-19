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
    user = @promotion.users.find(params[:id]) rescue nil
    if !user
      render :json => {:errors => ["User doesn't exist."]}, :status => 404 and return
    end
    render :json => user.profile and return
  end

  def create
    # this prolly shouldn't exist either, you can only create a profile in conjunction with a user
  end
  
  def update
    user = User.find(params[:id]) rescue nil
    if !user
      render :json => {:errors => ["User doesn't exist."]}, :status => 404 and return
    elsif user.profile.update_attributes(params[:profile])
      render :json => user.to_json
    elsif user.profile.errors
      render :json => {:errors => user.profile.errors.full_messages}, :status =>  422 and return
    else
      render :json => {:errors => "Something went wrong, Jake."}, :status =>  422 and return
    end
  end
  
  def destroy
    # you shouldn't be able to delete a profile separate from user
  end

end
