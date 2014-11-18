class UsersController < ApplicationController
  authorize :search, :user
  authorize :show, :create, :update, :public

  def index
    respond_with @promotion.users.find(:all,:include=>:profile)
  end

  def show
    user = @promotion.users.find(params[:id]) rescue nil
    if !user
      render :json => {:errors => ["User doesn't exist."]}, :status => 404 and return
    end
    render :json => user and return
  end

  def create
    params[:user][:profile] = Profile.new(params[:user][:profile]) if !params[:user][:profile].nil?
    user = @promotion.users.create(params[:user])
    if !user.valid?
      render :json => {:errors => user.errors.full_messages}, :status =>  422 and return
    else
      render :json => user and return
    end
  end
  
  def update
    user = User.find(params[:id]) rescue nil
    params[:user][:profile] = Profile.new(params[:user][:profile]) if !params[:user][:profile].nil?
    if !user
      render :json => {:errors => ["User doesn't exist."]}, :status => 404 and return
    elsif user.update_attributes(params[:user])
      render :json => user.to_json
    elsif user.errors
      render :json => {:errors => user.errors.full_messages}, :status =>  422 and return
    else
      render :json => {:errors => "Something went wrong, Jake."}, :status =>  422 and return
    end
  end
  
  def destroy
    user = User.find(params[:id]) rescue nil
    if !user
      render :json => {:errors => ["User doesn't exist."]}, :status => 404 and return
    elsif @user.master? && user.destroy
      render :json => user.to_json
    else
      render :json => {:errors => "You may not delete."}, :status =>  403 and return
    end
  end

  # this might not be working yet..
  def search
    search_string = "%#{params[:search_string]}%"
    conditions = ["users.email like ? or profiles.first_name like ? or profiles.last_name like ?",search_string, search_string, search_string]
    users = @promotion.users.find(:all,:include=>:profile,:conditions=>conditions)
    respond_with users
  end

end
