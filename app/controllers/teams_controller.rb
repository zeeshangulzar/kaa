class TeamsController < ApplicationController

  authorize :all, :user

  wrap_parameters :team

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.teams : Team
  end
  private :set_sandbox

  def index
    limit = (!params[:page_size].nil? && params[:page_size].is_i?) ? params[:page_size].to_i : ApplicationController::PAGE_SIZE
    conditions = {
      :location_ids => (params[:location].nil? ? nil : params[:location].split(',')),
      :status       => params[:status].nil? ? 'official' : params[:status],
      :sort         => params[:sort],
      :sort_dir     => params[:sort_dir],
      :neighbors_id => params[:neighbors_id]
    }
    teams = @promotion.current_competition.nil? ? [] : @promotion.current_competition.leaderboard(conditions)
    count = @promotion.current_competition.nil? ? 0 : @promotion.current_competition.leaderboard(conditions, true)
    return HESResponder(teams, 'OK', nil, false, count)
  end
  
  def show
    team = @SB.find(params[:id]) rescue nil
    return HESResponder("Team", "NOT_FOUND") unless team && ( team.status != Team::STATUS[:deleted] || (@current_user && @current_user.master?) )
    team.attach(:team_members)
    return HESResponder(team)
  end
  
  def create
    if params[:competition_id]
      competition = @promotion.competitions.find(params[:competition_id]) rescue nil
    else
      competition = @promotion.current_competition
    end
    return HESResponder("Invalid competition.", "ERROR") if competition.nil?

    team = competition.teams.build(params[:team])
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
    team = @SB.find(params[:id]) rescue nil
    return HESResponder("Team", "NOT_FOUND") unless team && ( team.status != Team::STATUS[:deleted] || (@current_user && @current_user.master?) )
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

  def destroy
    team = @SB.find(params[:id]) rescue nil
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
    render :json => is_team_name_valid(params[:team][:name])[:is_valid] and return
  end
  
  def search    
    render :json => @competition.teams.all(:limit => 20, :conditions => ["name like ?","%#{params[:id]}%"]).collect{|t|{:id=>t.id,:name=>t.name}}
  end

end
