class TeamInvitesController < ApplicationController
  authorize :all, :user

  def index
    return HESResponder("Must provide user or team.", "ERROR") if params[:team_id].nil? && params[:user_id].nil?
    type = params[:user_id].nil? ? 'Team' : 'User'
    if type == "Team"
      team = type_obj = Team.find(params[:team_id]) rescue nil
      return HESResponder("Team", "NOT_FOUND") if !team
      if team.leader.id != @current_user.id && !@current_user.master?
        return HESResponder("You don't have access to the team's invites.", "DENIED")
      end
    else
      user = type_obj = User.find(params[:user_id]) rescue nil
      return HESResponder("User", "NOT_FOUND") if !user
      if user.id != @current_user.id && !@current_user.master?
        return HESResponder("You don't have access to the user's invites.", "DENIED")
      end
    end
    invites = type_obj.team_invites
    return HESResponder(invites)
  end

  def show
    team_user = TeamPhoto.find(params[:id]) rescue nil
    if !team_user
      return HESResponder("Team Photo", "NOT_FOUND")
    elsif team_user.team.owner.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not view this team user.", "DENIED")
    else
      return HESResponder(team_user)
    end
  end

  def create
    if params[:team_user].nil? || params[:team_user][:team_id].nil? || params[:team_user][:user_id].nil?
      return HESResponder('Must include team and user id.', "ERROR")
    end
    team = Team.find(params[:team_user][:team_id]) rescue nil
    user = Photo.find(params[:team_user][:user_id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !user
      return HESResponder("Photo", "NOT_FOUND")
    end
    if team.owner.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit this team.", "DENIED")
    end
    if !team.owner.friends.include?(user)
      return HESResponder("You are not friends with user.", "DENIED")
    end
    team_user = team.team_users.build(:user_id => user.id)
    TeamPhoto.transaction do
      team_user.save!
    end
    if !team_user.valid?
      return HESResponder(team_user.errors.full_messages, "ERROR")
    end
    return HESResponder(team_user)
  end

  def update
    team_user = TeamPhoto.find(params[:id]) rescue nil
    team = team_user.team rescue nil
    user = Photo.find(params[:team][:user_id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !team_user
      return HESResponder("Team Photo", "NOT_FOUND")
    elsif !user
      return HESResponder("Photo", "NOT_FOUND")
    end
    if team.owner.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not edit this team.", "DENIED")
    end
    if !team.owner.friends.include?(user)
      return HESResponder("You are not friends with user.", "DENIED")
    end
    TeamPhoto.transaction do
      team_user.update_attributes(params[:team_user])
    end
    if !team_user.valid?
      return HESResponder(team_user.errors.full_messages, "ERROR")
    end
    return HESResponder(team_user)
  end

  def destroy
    team_user = TeamPhoto.find(params[:id]) rescue nil
    if !team_user
      return HESResponder("Team Photo", "NOT_FOUND")
    elsif (team_user.team.owner.id == @current_user.id || @current_user.master?) && team_user.destroy
      return HESResponder(team_user)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end
