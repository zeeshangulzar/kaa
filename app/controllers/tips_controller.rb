class TipsController < ContentController
  # if you don't see code, or don't see much code
  # it's because lib/content/content_controller.rb is working :-)
  def index
    if !@current_user || @current_user.user?
      # average joe does not need the markdown -- because we can just give him HTML
      if !params[:day].nil? && params[:day].is_i?
        tips = @content_model_class_name.for_promotion(@promotion).select(@content_model_class_name.column_names_minus_markdown).where("day <= #{params[:day]}")
      else
        tips = @content_model_class_name.for_promotion(@promotion).select(@content_model_class_name.column_names_minus_markdown).all
      end
      return HESResponder(tips)
    else
      # non-average joe may need the markdown -- because master is the editor of the markdown... maybe others are, too
      return HESResponder(@content_model_class_name.for_promotion(@promotion).all)
    end
  end
end
