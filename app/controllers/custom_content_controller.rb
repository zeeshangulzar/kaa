class CustomContentController < ApplicationController
  authorize :index, :show, :public
  authorize :create, :update, :destroy, :copy, :reorder, :master
  
  def index
    conditions = {
      :category => params[:category].nil? ? nil : params[:category],
      :key      => params[:key].nil? ? nil : params[:key],
      :group    => params[:group].nil? ? nil : params[:group],
      :hidden   => (params[:hidden].nil? || params[:hidden] == 'false') ? false : nil
    }
    custom_content = CustomContent.for(@promotion, conditions)
    return HESResponder(CustomContent.keyworded(custom_content, @promotion, @current_user))
  end

  def show
    custom_content = CustomContent.find(params[:id]) rescue nil
    return HESResponder("Custom Content", "NOT_FOUND") if !custom_content
    return HESResponder("Not allowed.", "DENIED") if !custom_content.promotion_id.nil? && @promotion.id != custom_content.promotion_id && (!@current_user || !@current_user.master?)
    if @current_user && @current_user.master?
      custom_content.attach(:custom_content_archives)
    end
    return HESResponder(CustomContent.keyworded(custom_content, @promotion, @current_user))
  end

  def create
    custom_content = CustomContent.new(params[:custom_content])
    return HESResponder(custom_content.errors.full_messages, "ERROR") if !custom_content.valid?
    image_url = nil
    if params[:custom_content][:image] && !params[:custom_content][:image].starts_with?("/tmp/uploaded_images")
      image_url = params[:custom_content].delete(:image)
    end
    CustomContent.transaction do
      custom_content.save!
      if !image_url.nil? && custom_content.reload && !custom_content.id.nil?
        CustomContent.connection.execute("UPDATE custom_content set image = #{CustomContent.sanitize(image_url)} WHERE id = #{custom_content.id} LIMIT 1")
      end
    end
    CustomContent.uncached do
      custom_content = CustomContent.find(custom_content.id)
    end
    return HESResponder(CustomContent.keyworded(custom_content, @promotion, @current_user))
  end

  def update
    custom_content = CustomContent.find(params[:id]) rescue nil
    return HESResponder("Custom Content", "NOT_FOUND") if !custom_content
    CustomContent.transaction do
      custom_content.update_attributes(params[:custom_content])
    end
    return HESResponder(CustomContent.keyworded(custom_content, @promotion, @current_user))
  end
  
  def destroy
    custom_content = CustomContent.find(params[:id])
    CustomContent.transaction do
      custom_content.destroy
    end
    return HESResponder()
  end

  def copy
    return HESResponder("Must provide from and to promotion.", "ERROR") if params[:from].nil? || params[:to].nil?
    from = params[:from]
    to = params[:to]
    category = params[:category]
    copied = CustomContent::copy(from, to, category)
    return HESResponder("Unknown error copying content.", "ERROR") if !copied
    return HESResponder(copied)
  end

  # resequencing of a custom content category, follow along cuz this one gets a bit hairy
  def reorder
    # must include a promotion, the sequence and the category
    return HESResponder("Must provide promotion, sequence and category.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array) || params[:category].nil? || params[:promotion_id].nil?
    custom_content = CustomContent.for(@promotion, {:category => params[:category], :hidden => true})
    
    # make sure the posted sequence contains every content id for the category
    cc_ids = custom_content.collect{|content|content.id}
    return HESResponder("Content ids are mismatched.", "ERROR") if (cc_ids & params[:sequence]) != cc_ids

    # make a hash to keep track of the posted sequence ids (which may include defaults) vs. the new ids (after cloning)
    mapped_ids = Hash[ *params[:sequence].collect { |v| [ v, v ] }.flatten ]

    # does the content include defaults? if so and we're not editing default's content, clone it and keep track of new ids below...
    default_content = custom_content.select{|content|content.promotion_id.nil?}
    if !@promotion.is_default? && default_content
      # copy defaults..
      default_content.each{|content|
        copied_content = CustomContent::copy(Promotion::get_default, @promotion, { :ids => content.id })
        # update the mapping hash with the new id so we can reference it during resequencing
        mapped_ids[content.id] = copied_content.id
      }
    end
    
    sequence = 0
    params[:sequence].each{ |cc_id|
      cc = CustomContent.find(mapped_ids[cc_id]) # note that we use the map instead of the posted ids, in case we've cloned content
      cc.update_attributes(:sequence => sequence)
      sequence += 1
    }
    
    # just for giggles, regrab everything uncached...
    CustomContent.uncached do
      custom_content = CustomContent.for(@promotion, {:category => params[:category], :hidden => true})
    end
    return HESResponder(custom_content)
  end
end