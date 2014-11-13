class UsersController < ApplicationController
  authorize :show,:search,:user
  authorize :create,:public

  def index
    respond_with @promotion.users.find(:all,:include=>:profile)
  end

  def show
    respond_with @promotion.users.find(params[:id])
  end

  def search
    search_string = "%#{params[:search_string]}%"
    conditions = ["users.email like ? or profiles.first_name like ? or profiles.last_name like ?",search_string, search_string, search_string]
    users = @promotion.users.find(:all,:include=>:profile,:conditions=>conditions)
    respond_with users 
  end

  def create
    user = @promotion.users.create(params[:user])
    user.build_profile(params[:profile]||{})
  end

end
