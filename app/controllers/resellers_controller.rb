class ResellersController < ApplicationController
  authorize :index,:master

  def index
    return HESResponder(Reseller.all)
  end

  def show
    return HESResponder(Reseller.find(params[:id]))
  end
end
