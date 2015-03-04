class LongTermGoalsController < ApplicationController
  authorize :curated_images, :index, :show, :create, :update, :destroy, :user

  def curated_images
    handle = HesCloudStorage::HesCloudDirectory.new("long_term_goals/curated")
    curated = handle.files.collect{|f|f.path}
    return HESResponder(curated)
  end

  def index
    ltgs = @current_user.long_term_goals
    return HESResponder(ltgs)
  end

  def show
    ltg = LongTermGoal.find(params[:id]) rescue nil
    return HESResponder("Long Term Goal", "NOT_FOUND") if ltg.nil?
    return HESResponder(ltg)
  end

  def create
    if !params[:curated_image].nil?
      # TODO: make more secure, check for size and errors, etc.
      uri = URI.parse(params[:curated_image])
      parts = uri.host.split('.')
      if parts[-2] + '.' + parts[-1] == 'hesapps.com'
        f = "public/tmp/uploaded_files/#{SecureRandom.hex(32)}.png"
        open(f, 'wb') do |file|
          file << open(uri).read
        end
      end
      params[:long_term_goal][:image] = f
    end
    ltg = @current_user.long_term_goals.build(params[:long_term_goal])
    return HESResponder(ltg.errors.full_messages, "ERROR") if !ltg.valid?
    LongTermGoal.transaction do
      ltg.save!
    end
    return HESResponder(ltg)
  end

  def update
    ltg = @current_user.long_term_goals.find(params[:id]) rescue nil
    ltg.assign_attributes(params[:long_term_goal])
    return HESResponder(ltg.errors.full_messages, "ERROR") if !ltg.valid?
    LongTermGoal.transaction do
      ltg.save!
    end
    return HESResponder(ltg)
  end

  def destroy
    ltg = @current_user.long_term_goals.find(params[:id]) rescue nil
    return HESResponder("Long Term Goal", "NOT_FOUND") if ltg.nil?
    LongTermGoal.transaction do
      ltg.destroy
    end
    return HESResponder(ltg)
  end


end
