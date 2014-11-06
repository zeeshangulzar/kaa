class UsersController < ApplicationController
  authorize :show,:search,:user
  authorize :create,:public

  def index
    respond_with @promotion.users.find(:all,:include=>:contact)
  end

  def show
    respond_with @promotion.users.find(params[:id])
  end

  def search
    search_string = "%#{params[:search_string]}%"
    conditions = ["contacts.email like ? or contacts.first_name like ? or contacts.last_name like ?",search_string, search_string, search_string]
    users = @promotion.users.find(:all,:include=>:contact,:conditions=>conditions)
    respond_with users 
  end
end
