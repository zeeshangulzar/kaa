class ResellersController < ApplicationController
  authorize :index,:master

  def index
    respond_with Reseller.all
  end

  def show
    respond_with Reseller.find(params[:id])
  end
end
