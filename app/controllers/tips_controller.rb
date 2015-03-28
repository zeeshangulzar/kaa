class TipsController < ContentController
  # if you don't see code, or don't see much code
  # it's because lib/content/content_controller.rb is working :-)
  wrap_parameters :tip
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
      # non-average joe may need the markdown -- because master is the editor of the markdown... maybe others are, too
      tips = Tip.for_promotion(@promotion).desc.all
    end
    #}
    return HESResponder(tips)
  end
end
