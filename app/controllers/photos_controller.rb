class PhotosController < ApplicationController
	respond_to :json

	before_filter :get_photoable, :only => [:index, :create, :destroy]
	authorize :index, :show, :update, :create, :destroy, :all_team_photos, :user

	# Get the notificationable type and user, or render an error.
	def get_photoable
    @photoable = nil
    if params[:photoable_type] && params[:photoable_id]
      @photoable = params[:photoable_type].singularize.camelcase.constantize.find(params[:photoable_id]) rescue nil
      @photoable = nil if !@photoable.respond_to?('photos')
    end
    return HESResponder("Could not find photoable object.", "ERROR") if !@photoable
	end

	def index
		return HESResponder(@photoable.photos)
	end

	def show
		photo = Photo.find(params[:id]) rescue nil
    return HESResponder("Photo", "NOT_FOUND") if !photo
		return HESResponder(photo)
	end

	def create
    params[:photo][:user_id] = @current_user.id
    photo = @photoable.photos.build(params[:photo])
    return HESResponder(photo.errors.full_messages) if !photo.valid?
    Photo.transaction do
      photo.save!
    end
    return HESResponder(photo)
	end

  def update
    photo = Photo.find(params[:id]) rescue nil
    return HESResponder("Photo", "NOT_FOUND") if !photo
    if @current_user.coordinator_or_above? || @current_user.id == photo.user_id
      attrs = scrub(params[:photo], Photo)
    else
      attrs = scrub(params[:photo], ['flagged'])
    end
    if attrs[:flagged] == 1
      attrs[:flagged_by] = @current_user.id
    end
    photo.assign_attributes(attrs)
    return HESResponder(photo.errors.full_messages) if !photo.valid?
    Photo.transaction do
      photo.save!
    end
    return HESResponder(photo)
  end

	def destroy
		photo = Photo.find(params[:id]) rescue nil
    return HESResponder("Photo", "NOT_FOUND") if !photo
    if @current_user.coordinator_or_above? || @current_user.id == photo.user_id
      Photo.transaction do
        photo.destroy
      end
    end
    return HESResponder(photo)
	end

  def all_team_photos
    return HESResponder("No competition.", "NOT_FOUND") if !@promotion.current_competition
    photos = Photo.where("photoable_type = 'Team' AND photoable_id IN (#{@promotion.current_competition.teams.collect{|team|team.id}.join(",")})").order("created_at DESC")
    return HESResponder(photos)
  end
end
