class TeamMembersController < ApplicationController
  authorize :index, :show, :user
  authorize :create, :update, :destroy, :master

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.teams : Team
  end
  private :set_sandbox

  def index
    return HESResponder("Must provide a team.", "ERROR") if !params[:team_id]
    team = @SB.find(params[:team_id]) rescue nil
    return HESResponder("Team", "NOT_FOUND") if !team
    return HESResponder(team.members)
  end

  def show
    team_member = TeamMember.find(params[:id]) rescue nil
    if !team_member
      return HESResponder("Team User", "NOT_FOUND")
    elsif team_member.id != @current_user.id && !@current_user.master? && (!team_member.team.leader || team_member.team.leader.id != @current_user.id)
      return HESResponder("You may not view this team member.", "DENIED")
    else
      return HESResponder(team_member)
    end
  end

  def create
    if params[:team_member].nil? || params[:team_member][:team_id].nil? || params[:team_member][:user_id].nil?
      return HESResponder('Must include team and user id.', "ERROR")
    end
    team = Team.find(params[:team_member][:team_id]) rescue nil
    user = User.find(params[:team_member][:user_id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !user
      return HESResponder("User", "NOT_FOUND")
    end
    if !@current_user.master? && @current_user.promotion_id != team.promotion_id
      return HESResponder("You may not edit this team member.", "DENIED")
    end
    team_member = team.team_members.build(:user_id => user.id, :competition_id => team.competition_id)
    if !team_member.valid?
      return HESResponder(team_member.errors.full_messages, "ERROR")
    end
    TeamMember.transaction do
      team_member.save!
    end
    return HESResponder(team_member)
  end

  def update
    team_member = TeamMember.find(params[:id]) rescue nil
    team = team_member.team rescue nil
    user = User.find(params[:team_member][:user_id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !team_member
      return HESResponder("Team Member", "NOT_FOUND")
    elsif !user
      return HESResponder("User", "NOT_FOUND")
    end
    if !@current_user.master? && @current_user.promotion_id != team.promotion_id
      return HESResponder("You may not edit this team member.", "DENIED")
    end
    if !team_member.valid?
      return HESResponder(team_member.errors.full_messages, "ERROR")
    end
    TeamMember.transaction do
      team_member.update_attributes(params[:team_member])
    end
    return HESResponder(team_member)
  end

  def destroy
    team_member = TeamMember.find(params[:id]) rescue nil
    if !team_member
      return HESResponder("Team Member", "NOT_FOUND")
    elsif @current_user.master? || @current_user.promotion_id == team.promotion_id
      if team_member.destroy
        return HESResponder(team_member)
      else
        return HESResponder("Error deleting.", "ERROR")
      end
    else
      return HESResponder("You may not delete this user.", "DENIED")
    end
  end

end
