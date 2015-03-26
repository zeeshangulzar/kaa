class TipsController < ContentController
  # if you don't see code, or don't see much code
  # it's because lib/content/content_controller.rb is working :-)
  wrap_parameters :tip

  def index
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
      return HESResponder(tips)
    else
      if !params[:start].nil? && !params[:end].nil?
        # handle date range for dashboard
        start_date = params[:start].is_i? ? Time.at(params[:start].to_i).to_date : params[:start].to_date
        end_date = params[:end].is_i? ? Time.at(params[:end.to_i]).to_date : params[:end].to_date
        s = Tip.get_day_number_from_date(start_date)
        e = Tip.get_day_number_from_date(end_date)
        tips = Tip.for_promotion(@promotion).asc.where("day BETWEEN #{s} AND #{e}")
      else
        tips = Tip.for_promotion(@promotion).desc.all
      end
      return HESResponder(tips)
    end
  end
end
