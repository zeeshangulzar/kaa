class ContentController < ApplicationController
  authorize :create, :update, :destroy, :master
  authorize :index, :show, :public

  before_filter :set_content_model

  # turns the string "TipsController" into the class constant Tip
  def set_content_model
    @content_model_class_name = self.class.name.gsub(/Controller/,'').singularize.constantize
  end

  # returns all content models for the current promotion -- whether they're default or custom
  def index
    if !@current_user || @current_user.user?
      # average joe does not need the markdown -- because we can just give him HTML
      HESResponder @content_model_class_name.for_promotion(@promotion).select(@content_model_class_name.column_names_minus_markdown).all
    else
      # non-average joe may need the markdown -- because master is the editor of the markdown... maybe others are, too
      HESResponder @content_model_class_name.for_promotion(@promotion).all
    end
  end

  def show
    obj = @content_model_class_name.for_promotion(@promotion).find(params[:id]) rescue nil
    return HESResponder("Object", "NOT_FOUND") if !obj
    return HESResponder(@content_model_class_name.for_promotion(@promotion).find(params[:id]))
  end

  def create
    @obj = @content_model_class_name.for_promotion(@promotion).new(params[@content_model_class_name.name.downcase.underscore.to_sym])
    if @obj.valid?
      @content_model_class_name.transaction do
        @obj.save!
      end
      return HESResponder(@obj)
    elsif @obj.errors
      return HESResponder(@obj.errors.full_messages, "ERROR")
    else
      return HESResponder("General error.", "ERROR")
    end
  end


  def update
    @obj = @content_model_class_name.for_promotion(@promotion).find(params[:id])
    @content_model_class_name.transaction do
      @obj.update_attributes(params[@content_model_class_name.name.downcase.underscore.to_sym])
    end
    if @obj.valid?
      return HESResponder(@obj)
    elsif @obj.errors
      return HESResponder(@obj.errors.full_messages, "ERROR")
    else
      return HESResponder("General error.", "ERROR")
    end
  end
 
  def destroy
    @obj = @content_model_class_name.for_promotion(@promotion).find(params[:id])
    @content_model_class_name.transaction do
      @obj.destroy
    end
    return HESResponder(@obj)
  end

  def destroy_all
    if params[:confirm].to_s.downcase == 'true'
    
    else
      # return error -- this is a bulk delete... make SURE this is not accidentally called
      return HESResponder("You must set :confirm to 'true' in order to destroy all #{@content_model_class_name.name.pluralize}.", "ERROR")
    end
  end

  def copy_default
  end

  # example:  params=>[:id,:id,:id]
  def resequence
  end
end
