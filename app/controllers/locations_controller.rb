# Controller for handling all location type requests
class LocationsController < ApplicationController

  respond_to :json
  
  authorize :index, :show, :public
  authorize :update, :create, :destroy, :upload, :master

  before_filter :set_sandbox
  def set_sandbox
    @SB = use_sandbox? ? @promotion.locations : Location
  end
  private :set_sandbox

  def index
    if !params[:location_id].nil?
      location = @SB.find(params[:location_id]) rescue nil
      return HESResponder("Location", "NOT_FOUND") if !location
      locations = location.locations
    else
      locations = @promotion.nested_locations
    end
    return HESResponder(locations)
  end

  def show
    location = @SB.find(params[:id])
    return HESResponder(location)
  end

  def create
    if params[:locations_file].nil?
      location = nil
      Location.transaction do
        location = @SB.create(params[:location])
      end
      return HESResponder(location.errors.full_messages, "ERROR") if !location || !location.valid?
      return HESResponder(location)
    else
      upload_locations(params[:locations_file])
      return HESResponder(@promotion.nested_locations)
    end
  end

  def update
    location = @SB.find(params[:id])
    Location.transaction do
      location.update_attributes(params[:location])
    end
    return HESResponder(location)
  end

  def destroy
    location = @SB.find(params[:id])
    if location.destroy
      return HESResponder(location)
    else
      return HESResponder("Cannot destroy a location that has models assigned to it", "ERROR")
    end
  end

  def upload_locations(file)
    require 'fileutils'
    Location.transaction do
      row_index = 0
      @cols = []
      FasterCSV.foreach(file.path) do |row|
        process_csv_row(row, row_index)
        row_index += 1
      end
    #  PromotionLocation.connection.execute "update promotion_locations set sequence = id where promotion_id = #{@promotion.id}"
    end
  end
  private :upload_locations

  def process_csv_row(row, row_index)
    parent = @promotion
    if row_index == 0
      row.size.times do |t|
        depth = @promotion.location_labels.index(row[t])
        if !depth.nil?
          @cols[depth] = t
        end
      end
    end
    if @cols.empty?
      row.size.times do |t|
        return if row[t].to_s.strip.empty?
        parent_id = parent.is_a?(Promotion) ? nil : parent.id
        parent = parent.locations.find_or_create_by_promotion_id_and_parent_location_id_and_name(@promotion.id, parent_id, row[t])
      end
    elsif row_index > 0
      @cols.each{ |col|
        return if row[col].to_s.strip.empty?
        parent_id = parent.is_a?(Promotion) ? nil : parent.id
        parent = parent.locations.find_or_create_by_promotion_id_and_parent_location_id_and_name(@promotion.id, parent_id, row[col])
      }
    end
  end
  private :process_csv_row

  # resequencing of a custom content category, follow along cuz this one gets a bit hairy
  def reorder
    # must include a promotion, the sequence and the category
    return HESResponder("Must provide parent location and sequence.", "ERROR") if params[:sequence].nil? || !params[:sequence].is_a?(Array) || !defined?(params[:parent_location_id])
    
    locations = params[:parent_location_id].nil? ? @promotion.locations.top : @promotion.locations.find_by_id(params[:parent_location_id]).locations
    
    # make sure the posted sequence contains every content id for the category
    location_ids = locations.collect{|location|location.id}
    return HESResponder("Location ids are mismatched.", "ERROR") if (location_ids & params[:sequence]) != location_ids
    
    sequence = 0
    params[:sequence].each{ |location_id|
      location = Location.find(location_id)
      location.update_attributes(:sequence => sequence)
      sequence += 1
    }
    return HESResponder() # bob just wants a 200...
  end
  
end
