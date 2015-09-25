class TipsController < ContentController
  # if you don't see code, or don't see much code
  # it's because lib/content/content_controller.rb is working :-)
  wrap_parameters :tip

  authorize :user_favorites, :user
  authorize :reorder, :master

  def index
    # disabling cache for now..
    #tips = hes_cache_fetch('tips') {
    if !@current_user || @current_user.user? || (!params[:type].nil? && params[:type] == 'widget')
      # average joe does not need the markdown -- because we can just give him HTML
      if !params[:day].nil? && params[:day].is_i?
        tips = Tip.for_promotion(@promotion).desc.select(Tip.column_names_minus_markdown).where("day <= #{params[:day]}")
        if !params[:minimum].nil? && params[:minimum].is_i?
          min = params[:minimum].to_i
          diff = min - tips.size
          if diff > 0
            # number of tips returned is less than minimum the app wants
            # so first figure out how may weekdays are in last year
            last_year_limit = Tip::get_weekdays_in_year(@promotion.current_date.year.to_i - 1)
            # then grab the tips in day DESC order limited to the diff
            tips2 = Tip.for_promotion(@promotion).desc.select(Tip.column_names_minus_markdown).where("day <= #{last_year_limit}").limit(diff)
            # switch it around so it's in the same order as the rest of tips and combine the arrays
            tips = tips + tips2
          end
        end
      else
        tips = Tip.for_promotion(@promotion).desc.select(Tip.column_names_minus_markdown).all
      end
    else
      if !params[:start].nil? && !params[:end].nil?
        # handle date range for dashboard
        start_date = params[:start].is_i? ? Time.at(params[:start].to_i).to_date : params[:start].to_date
        end_date = params[:end].is_i? ? Time.at(params[:end.to_i]).to_date : params[:end].to_date
        s = Tip.get_day_number_for_promotion(@promotion, start_date)
        e = Tip.get_day_number_for_promotion(@promotion, end_date)
        tips = Tip.for_promotion(@promotion).asc.where("day BETWEEN #{s} AND #{e}")
      else
        # non-average joe may need the markdown -- because master is the editor of the markdown... maybe others are, too
        tips = Tip.for_promotion(@promotion).desc.all
      end
    end
    return HESResponder(tips)
  end

  def reorder
    return HESResponder("Must provide sequence.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array)
    tips = Tip.for_promotion(@promotion).desc.all

    tip_ids = tips.collect{|tip|tip.id}
    return HESResponder("Tip ids are mismatched.", "ERROR") if (tip_ids & params[:sequence]) != tip_ids
    day = 1
    params[:sequence].each{ |tip_id|
      tip = Tip.find(tip_id)
      tip.update_attributes(:day => day)
      day += 1
    }
    tips = Tip.for_promotion(@promotion).desc.all
    return HESResponder(tips)
  end

  def user_favorites
    likes = @current_user.likes.where(:likeable_type => "Tip")
    return HESResponder([]) if likes.empty?
    tips = Tip.where(:id => likes.collect{|like|like.likeable_id})
    return HESResponder(tips)
  end

end
