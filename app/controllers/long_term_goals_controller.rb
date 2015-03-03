class LongTermGoalsController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :user

  def index
    ltgs = @current_user.long_term_goals
    return HESResponder(ltgs)
  end

  def show
    ltg = LongTermGoal.find(params[:id]) rescue nil
    return HESResponder("Long Term Goal", "NOT_FOUND") if ltg.nil?
    return HESResponder(ltg)
  end

  def create
    ltg = @current_user.long_term_goals.build(params[:long_term_goal])
    return HESResponder(ltg.errors.full_messages, "ERROR") if !ltg.valid?
    LongTermGoal.transaction do
      ltg.save!
    end
    return HESResponder(ltg)
  end

  def update
    ltg = @current_user.long_term_goals.find(params[:id]) rescue nil
    ltg.assign_attributes(params[:long_term_goal])
    return HESResponder(ltg.errors.full_messages, "ERROR") if !ltg.valid?
    LongTermGoal.transaction do
      ltg.save!
    end
    return HESResponder(ltg)
  end

  def destroy
    ltg = @current_user.long_term_goals.find(params[:id]) rescue nil
    return HESResponder("Long Term Goal", "NOT_FOUND") if ltg.nil?
    LongTermGoal.transaction do
      ltg.destroy
    end
    return HESResponder(ltg)
  end


end
