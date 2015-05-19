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
    if !params[:type].nil? && TeamInvite::TYPE.stringify_keys.keys.include?(params[:type])
      if type == "Team"
        invites = type_obj.team_invites.send(params[:type])
      else
        invites = type_obj.team_invites(params[:type])
      end
    else
      invites = type_obj.team_invites
    end
    return HESResponder(invites)
  end

  def show
    team_invite = TeamInvite.find(params[:id]) rescue nil
    if !team_invite
      return HESResponder("Team Invite", "NOT_FOUND")
    elsif team_invite.user_id != @current_user.id && team_invite.team.leader.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not view this invite.", "DENIED")
    else
      return HESResponder(team_invite)
    end
  end

  def create
    return HESResponder("Bad request.", "ERROR") if params[:team_invite].nil?
    return HESResponder("Invite type required.", "ERROR") if params[:team_invite][:invite_type].nil?
    if params[:team_invite][:invite_type] == TeamInvite::TYPE[:requested]
      invite_type = TeamInvite::TYPE[:requested]
      if params[:team_invite].nil? || params[:team_invite][:team_id].nil? || params[:team_invite][:user_id].nil?
        return HESResponder('Must include team and user id.', "ERROR")
      end
    elsif params[:team_invite][:invite_type] == TeamInvite::TYPE[:invited]
      invite_type = TeamInvite::TYPE[:invited]
      if params[:team_invite].nil? || params[:team_invite][:team_id].nil? || (params[:team_invite][:user_id].nil? && params[:team_invite][:email].nil?)
        return HESResponder('Must include team id, and user id or email.', "ERROR")
      end
    else
      return HESResponder("Invalid invite type.", "ERROR")
    end
    email = params[:team_invite][:email] rescue nil
    team = Team.find(params[:team_invite][:team_id]) rescue nil
    user = User.find(params[:team_invite][:user_id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !user && invite_type == TeamInvite::TYPE[:requested]
      return HESResponder("User", "NOT_FOUND")
    elsif !user && !email && invite_type == TeamInvite::TYPE[:invited]
      return HESResponder("Email or valid user required.", "ERROR")
    end
    
    if user && !user.current_team.nil?
      return HESResponder("User is already on a team", "ERROR")
    end

    if invite_type == TeamInvite::TYPE[:requested]
      if @current_user.id != user.id
        return HESResponder("Impersonation attempt logged.", "ERROR")
      else
        team_invite = team.team_invites.build(:user_id => user.id, :competition_id => team.competition_id, :invite_type => TeamInvite::TYPE[:requested])
      end
    elsif invite_type == TeamInvite::TYPE[:invited]
      if team.leader.id != @current_user.id && !@current_user.master?
        return HESResponder("You may not invite people for this team.", "DENIED")
      else
        if user
          team_invite = team.team_invites.build(:user_id => user.id, :competition_id => team.competition_id, :invited_by => @current_user.id, :invite_type => TeamInvite::TYPE[:invited], :message => params[:team_invite][:message])
        else
          team_invite = team.team_invites.build(:email => email, :competition_id => team.competition_id, :invited_by => @current_user.id, :invite_type => TeamInvite::TYPE[:invited], :message => params[:team_invite][:message])
        end
      end
    end
    if !team_invite.valid?
      return HESResponder(team_invite.errors.full_messages, "ERROR")
    else
      TeamInvite.transaction do
        team_invite.save!
      end
    end
    return HESResponder(team_invite)
  end

  def update
    team_invite = TeamInvite.find(params[:id]) rescue nil
    return HESResponder("Team Invite", "NOT_FOUND") if !team_invite
    
    team = team_invite.team rescue nil
    user = team_invite.user rescue nil

    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif !user
      return HESResponder("User", "NOT_FOUND")
    end

    if !user.current_team.nil?
      return HESResponder("User is already on a team", "ERROR")
    end

    if team_invite.invite_type == TeamInvite::TYPE[:invited]
      if team_invite.user_id != @current_user.id && !@current_user.master?
        # this is an invite and @current_user is not the invited user
        return HESResponder("Cannot modify this invitation.", "DENIED")
      end
    elsif team_invite.invite_type == TeamInvite::TYPE[:requested]
      if team_invite.team.leader.id != @current_user.id && !@current_user.master?
        # this is a request and @current_user is not the team leader
        return HESResponder("Cannot modify this invitation.", "DENIED")
      end
    end

    team_invite.assign_attributes(scrub(params[:team_invite], ['status']))
    if !team_invite.valid?
      return HESResponder(team_invite.errors.full_messages, "ERROR")
    end
    TeamInvite.transaction do
      team_invite.save!
    end
    return HESResponder(team_invite)
  end

  def destroy
    team_invite = TeamInvite.find(params[:id]) rescue nil
    if !team_invite
      return HESResponder("Team Invite", "NOT_FOUND")
    elsif (team_invite.user_id == @current_user.id || team_invite.team.leader.id == @current_user.id || @current_user.master?)
      if team_invite.destroy
        return HESResponder(team_invite)
      else
        return HESResponder("Error deleting.", "ERROR")
      end
    else
      return HESResponder("Cannot modify this invitation.", "DENIED")
    end
  end

end
