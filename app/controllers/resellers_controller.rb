class ResellersController < ApplicationController

  authorize :all, :master

  def index
    resellers = Reseller.all
    return HESResponder(resellers)
  end

  def show
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller", "NOT_FOUND")
    end
    return HESResponder(reseller)
  end

  def create
    reseller = Reseller.create(params[:reseller])
    if !reseller.valid?
      return HESResponder(reseller.errors.full_messages, "ERROR")
    else
      return HESResponder(reseller)
    end
  end

  def update
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller", "NOT_FOUND")
    else
      Reseller.transaction do
        reseller.update_attributes(params[:reseller])
      end
      if !reseller.valid?
        return HESResponder(reseller.errors.full_messages, "ERROR")
      else
        return HESResponder(reseller)
      end
    end
  end

  def destroy
    reseller = Reseller.find(params[:id])
    if !reseller
      return HESResponder("Reseller", "NOT_FOUND")
    elsif reseller.destroy
      return HESResponder(reseller)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end
