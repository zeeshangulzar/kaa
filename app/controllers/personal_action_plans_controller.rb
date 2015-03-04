class PersonalActionPlansController < ApplicationController
  authorize :index, :show, :create, :update, :destroy, :user

  def index
    paps = @current_user.personal_action_plans
    return HESResponder(paps)
  end

  def show
    pap = PersonalActionPlan.find(params[:id]) rescue nil
    return HESResponder("Personal Action Plan", "NOT_FOUND") if pap.nil?
    return HESResponder(pap)
  end

  def create
    pap = @current_user.personal_action_plans.build(params[:personal_action_plan])
    return HESResponder(pap.errors.full_messages, "ERROR") if !pap.valid?
    PersonalActionPlan.transaction do
      pap.save!
    end
    return HESResponder(pap)
  end

  def update
    pap = @current_user.personal_action_plans.find(params[:id]) rescue nil
    pap.assign_attributes(params[:personal_action_plan])
    return HESResponder(pap.errors.full_messages, "ERROR") if !pap.valid?
    PersonalActionPlan.transaction do
      pap.save!
    end
    return HESResponder(pap)
  end

  def destroy
    pap = @current_user.personal_action_plans.find(params[:id]) rescue nil
    return HESResponder("Personal Action Plan", "NOT_FOUND") if pap.nil?
    PersonalActionPlan.transaction do
      pap.destroy
    end
    return HESResponder(pap)
  end


end
