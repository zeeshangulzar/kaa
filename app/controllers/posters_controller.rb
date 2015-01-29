class PostersController < ApplicationController
  authorize :current, :public
  authorize :index, :show, :user
  authorize :create, :update, :delete, :coordinator

  def current
    return HESResponder(@promotion.posters.where("posters.visible_date <= '#{@promotion.current_date}'").limit(1))
  end
  
  def index
    if params[:promotion_id]
      # /promotions/:id/posters
      p = Promotion.find(params[:promotion_id]) rescue nil
      return HESresponder("Promotion", "NOT_FOUND") if !p
      if @current_user.master? || (@current_user.coordinator? && @current_user.promotion_id == p.id)
        return HESResponder(p.posters)
      else
        return HESResponder("Not authorized.", "DENIED")
      end
    else
      # /posters
      options = {}
      options[:start] = params[:start].nil? ? @promotion.current_date.beginning_of_month : (params[:start].is_i? ? Time.at(params[:start].to_i).to_date : params[:start].to_date)
      options[:end] = params[:end].nil? ? (!params[:start].nil? ? options[:start].end_of_month : @promotion.current_date.end_of_month) : (params[:end].is_i? ? Time.at(params[:end.to_i]).to_date : params[:end].to_date)
      return HESResponder(@current_user.posters(options))
    end
  end

  def show
    poster = Poster.find(params[:id]) rescue nil
    # TODO: what can users see about a poster? specifically, one they haven't yet unlocked
    return HESResponder("Poster", "NOT_FOUND") if !poster
    if poster.promotion.id == @current_user.promotion_id || @current_user.master?
      return HESResponder(poster)
    else
      return HESResponder("You may not view other promotions' posters.", "DENIED")
    end
  end

  def create
    poster = @promotion.posters.build(params[:poster])
    if poster.valid?
      Poster.transaction do
        poster.save!
      end
      return HESResponder(poster)
    else
      return HESResponder(poster.errors.full_messages, "ERROR")
    end
  end

  def update
    poster = Poster.find(params[:id]) rescue nil
    return HESResponder("Poster", "NOT_FOUND") if !poster
    Poster.transaction do
      poster.update_attributes(params[:poster])
    end
    if !poster.valid?
      return HESResponder(poster.errors.full_messages, "ERROR")
    else
      return HESResponder(poster)
    end
  end

  def destroy
    poster = Poster.find(params[:id]) rescue nil
    if !poster
      return HESResponder("Poster", "NOT_FOUND")
    elsif @current_user.master? && poster.destroy
      return HESResponder(poster)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end

end