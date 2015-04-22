class TeamsController < ApplicationController

  authorize :all, :public

  wrap_parameters :team

  def index
    teams = []
    teams = @promotion.current_competition.teams unless @promotion.current_competition.nil?

    return HESResponder(teams)
  end
  
  def show
    team = Team.find(params[:id]) rescue nil
    return HESResponder("Team", "NOT_FOUND") if !team
    return HESResponder(team)
  end
  
  def create
    team = @promotion.current_competition.teams.build(params[:team])
    if !team.valid?
      return HESResponder(team.errors.full_messages, "ERROR")
    end
    Team.transaction do
      team.save!
      # TODO: after creating the team, we make the posting user the leader
      # will this affect coordinators/masters ability to create teams???
      team.team_members.create(:competition_id => team.competition_id, :user_id => @current_user.id, :is_leader => 1)
    end
    return HESResponder(team)
  end

  
  def update
    team = Team.find(params[:id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    else
      if team.leader.id != @current_user.id && !@current_user.coordinator_or_above?
        return HESResponder("You may not edit this team.", "DENIED")
      end
      Team.transaction do
        team.update_attributes(params[:team])
      end
      if !team.valid?
        return HESResponder(team.errors.full_messages, "ERROR")
      else
        return HESResponder(team)
      end
    end
  end

  def destroy
    team = Team.find(params[:id]) rescue nil
    if !team
      return HESResponder("Team", "NOT_FOUND")
    elsif team.leader.id != @current_user.id && !@current_user.master?
      return HESResponder("You may not delete this team.", "DENIED")
    end
    Team.transaction do
      team.destroy
    end
    return HESResponder(team)
  end

  def check_name
    respond_to do |format|
      format.json {render :json => is_team_name_valid(params[:team][:name])[:is_valid]}
    end
  end

  
  def search    
    render :json => @competition.teams.all(:limit => 20, :conditions => ["name like ?","%#{params[:id]}%"]).collect{|t|{:id=>t.id,:name=>t.name}}
  end

end