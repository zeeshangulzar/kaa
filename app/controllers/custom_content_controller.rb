class CustomContentController < ApplicationController
  authorize :index, :show, :public
  authorize :create, :update, :destroy, :master
  
  def index
    conditions = {
      :category => params[:category].nil? ? nil : params[:category],
      :key => params[:key].nil? ? nil : params[:key]
    }
    custom_content = @promotion.is_default? ? CustomContent.where(:promotion_id => nil) : CustomContent.for(@promotion, conditions)
    return HESResponder(custom_content)
  end

  def show
    custom_content = CustomContent.find(params[:id]) rescue nil
    return HESResponder("Custom Content", "NOT_FOUND") if !custom_content
    return HESResponder("Not allowed.", "DENIED") if !custom_content.promotion_id.nil? && @promotion.id != custom_content.promotion_id && !@current_user.master?
    if @current_user.master?
      custom_content.attach(:custom_content_archives)
    end
    return HESResponder(custom_content)
  end

  def create
    custom_content = CustomContent.new(params[:custom_content])
    return HESResponder(custom_content.errors.full_messages, "ERROR") if !custom_content.valid?
    CustomContent.transaction do
      custom_content.save!
    end
    return HESResponder(custom_content)
  end

  def update
    custom_content = CustomContent.find(params[:id]) rescue nil
    return HESResponder("Custom Content", "NOT_FOUND") if !custom_content
    CustomContent.transaction do
      custom_content.update_attributes(params[:custom_content])
    end
    return HESResponder(custom_content)
  end
  
  def destroy
    custom_content = CustomContent.find(params[:id])
    CustomContent.transaction do
      custom_content.destroy
    end
    return HESResponder(custom_content)
  end
end