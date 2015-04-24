class CompetitionsController < ApplicationController

  # GET /competitions
  # GET /competitions.xml
  def index
    respond_to do |format|
      format.html { render :layout => 'full'}
      format.xml  { render :xml => Competition.all }
      format.json {
        competitions = []
        
        @promotion.competitions.each do |c|
          competitions << [c.enrollment_starts_on.to_s,c.enrollment_ends_on.to_s, c.competition_starts_on.to_s, c.competition_ends_on.to_s, c.length_of_competition, c.team_size_min, c.team_size_max, c.freeze_team_scores.nil? ? "Not Set" : c.freeze_team_scores_on.to_s, c.has_preset_teams ? 'Yes' : 'No']
          if may? :competitions,:edit
            competitions.last << "edit^/promotions/#{@promotion.id}/competitions/#{c.id}/edit^_self"
          end
        end
        render :json => competitions.to_json
      }
    end
  end

  # GET /competitions/1
  # GET /competitions/1.xml
  def show
    @competition = Competition.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @competition }
    end
  end

  # GET /competitions/new
  # GET /competitions/new.xml
  def new
    @competition = @promotion.competitions.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @competition }
    end
  end

  # GET /competitions/1/edit
  def edit
    @competition = Competition.find(params[:id])
  end

  # POST /competitions
  # POST /competitions.xml
  def create
    @competition = @promotion.competitions.build(params[:competition])

    respond_to do |format|
      if @competition.save
        flash[:notice] = 'Competition was successfully created.'
        format.html { redirect_to("/promotions/#{@promotion.id}/competitions") }
        format.xml  { render :xml => @competition, :status => :created, :location => @competition }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @competition.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /competitions/1
  # PUT /competitions/1.xml
  def update
    @competition = Competition.find(params[:id])

    respond_to do |format|
      if @competition.update_attributes(params[:competition])
        flash[:notice] = 'Competition was successfully updated.'
        format.html { redirect_to("/promotions/#{@promotion.id}/competitions") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @competition.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /competitions/1
  # DELETE /competitions/1.xml
  def destroy
    @competition = Competition.find(params[:id])
    @competition.destroy

    respond_to do |format|
      format.html { redirect_to("/promotions/#{@promotion.id}/competitions") }
      format.xml  { head :ok }
    end
  end
end
